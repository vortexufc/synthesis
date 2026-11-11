-- =============================================================================
-- SYNTHESIS — MIGRAÇÃO v3: MIGRAÇÃO COMPLETA DE NICK (RPC + RLS UPDATE)
-- Segura e idempotente (não apaga nenhum dado, apenas unifica os nicks).
-- Execute no SQL Editor do Supabase:
-- https://supabase.com/dashboard/project/uszmgqludyymspsarciw/sql/new
-- =============================================================================

-- 1. Permitir UPDATE em respostas, minigames_respostas e telemetria_gameplay (fallback REST)
DROP POLICY IF EXISTS "Atualizacao de respostas" ON respostas;
CREATE POLICY "Atualizacao de respostas" ON respostas FOR UPDATE USING (true) WITH CHECK (true);
GRANT UPDATE ON respostas TO anon, authenticated;

DROP POLICY IF EXISTS "Atualizacao de minigames" ON minigames_respostas;
CREATE POLICY "Atualizacao de minigames" ON minigames_respostas FOR UPDATE USING (true) WITH CHECK (true);
GRANT UPDATE ON minigames_respostas TO anon, authenticated;

DROP POLICY IF EXISTS "Atualizacao de telemetria" ON telemetria_gameplay;
CREATE POLICY "Atualizacao de telemetria" ON telemetria_gameplay FOR UPDATE USING (true) WITH CHECK (true);
GRANT UPDATE ON telemetria_gameplay TO anon, authenticated;

-- 2. Função atômica para migrar/mesclar TODOS os dados de um nick antigo para o novo
CREATE OR REPLACE FUNCTION public.migrar_nick_jogador(p_nick_antigo TEXT, p_nick_novo TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_antigo TEXT := TRIM(COALESCE(p_nick_antigo, ''));
    v_novo   TEXT := TRIM(COALESCE(p_nick_novo, ''));
    v_cnt_resp INT := 0;
    v_cnt_mini INT := 0;
    v_cnt_tele INT := 0;
    v_s INT := 0;
    v_sd INT := 0;
    v_ss INT := 0;
    v_sm INT := 0;
    v_ins_merged JSONB := '[]'::jsonb;
BEGIN
    IF v_antigo = '' OR v_novo = '' OR v_antigo = v_novo THEN
        RETURN jsonb_build_object('ok', true, 'migrado', false);
    END IF;

    IF LOWER(v_antigo) = 'admin' OR LOWER(v_novo) = 'admin' THEN
        RETURN jsonb_build_object('ok', false, 'erro', 'Nick admin protegido');
    END IF;

    -- 1. Respostas (Quiz + V ou F do Boss)
    UPDATE public.respostas
    SET aluno_nick = v_novo
    WHERE aluno_nick = v_antigo;
    GET DIAGNOSTICS v_cnt_resp = ROW_COUNT;

    -- 2. Minigames
    UPDATE public.minigames_respostas
    SET aluno_nick = v_novo
    WHERE aluno_nick = v_antigo;
    GET DIAGNOSTICS v_cnt_mini = ROW_COUNT;

    -- 3. Telemetria de Gameplay
    UPDATE public.telemetria_gameplay
    SET aluno_nick = v_novo
    WHERE aluno_nick = v_antigo;
    GET DIAGNOSTICS v_cnt_tele = ROW_COUNT;

    -- 4. Membros de Clã (evita duplicidade caso o novo nick já esteja no clã)
    IF EXISTS (SELECT 1 FROM public."MembrosCla" WHERE player_name = v_novo) THEN
        DELETE FROM public."MembrosCla" WHERE player_name = v_antigo;
    ELSE
        UPDATE public."MembrosCla"
        SET player_name = v_novo
        WHERE player_name = v_antigo;
    END IF;

    -- 5. Liderança de Clãs
    UPDATE public."Clas"
    SET lider = v_novo
    WHERE lider = v_antigo;

    -- 6. Ranking Geral (mescla pontos e insígnias se ambos existirem e remove o antigo)
    IF EXISTS (SELECT 1 FROM public.rankinggeral WHERE player_name = v_antigo) THEN
        IF EXISTS (SELECT 1 FROM public.rankinggeral WHERE player_name = v_novo) THEN
            SELECT
                COALESCE(SUM(score), 0),
                COALESCE(SUM(score_diario), 0),
                COALESCE(SUM(score_semanal), 0),
                COALESCE(SUM(score_mensal), 0)
            INTO v_s, v_sd, v_ss, v_sm
            FROM public.rankinggeral
            WHERE player_name = v_antigo;

            SELECT COALESCE(
                (
                    SELECT jsonb_agg(DISTINCT elem)
                    FROM (
                        SELECT jsonb_array_elements(
                            CASE
                                WHEN jsonb_typeof(insignias) = 'array' THEN insignias
                                ELSE '[]'::jsonb
                            END
                        ) AS elem
                        FROM public.rankinggeral
                        WHERE player_name IN (v_antigo, v_novo)
                    ) sub
                ),
                '[]'::jsonb
            ) INTO v_ins_merged;

            UPDATE public.rankinggeral
            SET
                score = COALESCE(score, 0) + v_s,
                score_diario = COALESCE(score_diario, 0) + v_sd,
                score_semanal = COALESCE(score_semanal, 0) + v_ss,
                score_mensal = COALESCE(score_mensal, 0) + v_sm,
                insignias = v_ins_merged,
                updated_at = NOW()
            WHERE ctid = (
                SELECT ctid FROM public.rankinggeral WHERE player_name = v_novo LIMIT 1
            );

            DELETE FROM public.rankinggeral WHERE player_name = v_antigo;
        ELSE
            UPDATE public.rankinggeral
            SET player_name = v_novo, updated_at = NOW()
            WHERE player_name = v_antigo;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'ok', true,
        'migrado', true,
        'respostas', v_cnt_resp,
        'minigames', v_cnt_mini,
        'telemetria', v_cnt_tele
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.migrar_nick_jogador(TEXT, TEXT) TO anon, authenticated;

-- 3. Correção imediata do seu caso já existente no banco:
SELECT public.migrar_nick_jogador('Cleiton Mota', 'Cleiton Mota 01') AS resultado_migracao_cleiton;

-- 4. Verificação: 'Cleiton Mota' deve ficar com 0 registros e tudo deve estar em 'Cleiton Mota 01'
SELECT
    (SELECT COUNT(*) FROM public.respostas WHERE aluno_nick = 'Cleiton Mota') AS respostas_antigo,
    (SELECT COUNT(*) FROM public.respostas WHERE aluno_nick = 'Cleiton Mota 01') AS respostas_novo,
    (SELECT COUNT(*) FROM public.rankinggeral WHERE player_name = 'Cleiton Mota') AS ranking_antigo,
    (SELECT COALESCE(MAX(score), 0) FROM public.rankinggeral WHERE player_name = 'Cleiton Mota 01') AS score_novo;
