-- =============================================================================
-- SYNTHESIS — MIGRAÇÃO v2 (SEGURA, IDEMPOTENTE — NÃO PERDE DADOS)
-- Execute no SQL Editor: https://supabase.com/dashboard/project/uszmgqludyymspsarciw/sql/new
-- =============================================================================

-- 1. Adicionar colunas faltando em RESPOSTAS
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS tempo_resposta      FLOAT        DEFAULT 0.0;
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS alternativa_marcada VARCHAR(10)  DEFAULT '';
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS cla_aluno           VARCHAR(100) DEFAULT 'Nenhum';
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS consultas_grimorio  INT          DEFAULT 0;

-- 2. Adicionar coluna faltando em RANKINGGERAL
ALTER TABLE rankinggeral ADD COLUMN IF NOT EXISTS insignias JSONB DEFAULT '[]'::jsonb;

-- 3. Adicionar coluna faltando em CLÃS e MEMBROS
ALTER TABLE "Clas"      ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';
ALTER TABLE "MembrosCla" ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';

-- 4. Criar tabela TELEMETRIA DE GAMEPLAY (nova)
CREATE TABLE IF NOT EXISTS telemetria_gameplay (
    id           BIGSERIAL PRIMARY KEY,
    aluno_nick   VARCHAR(255) NOT NULL,
    escola_id    VARCHAR(100) DEFAULT 'geral',
    andar_id     INT NOT NULL DEFAULT 1,
    tipo_evento  VARCHAR(100) NOT NULL,
    valor        FLOAT DEFAULT 1.0,
    timestamp    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE telemetria_gameplay ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura de telemetria" ON telemetria_gameplay;
DROP POLICY IF EXISTS "Insercao de telemetria" ON telemetria_gameplay;
CREATE POLICY "Leitura de telemetria"  ON telemetria_gameplay FOR SELECT USING (true);
CREATE POLICY "Insercao de telemetria" ON telemetria_gameplay FOR INSERT WITH CHECK (true);
GRANT SELECT ON telemetria_gameplay TO anon, authenticated;
GRANT INSERT ON telemetria_gameplay TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE telemetria_gameplay_id_seq TO anon, authenticated;

-- 5. Criar tabela ANALYTICS DE MINIGAMES (nova)
CREATE TABLE IF NOT EXISTS minigames_respostas (
    id            BIGSERIAL PRIMARY KEY,
    aluno_nick    VARCHAR(255) NOT NULL,
    escola_id     VARCHAR(100) DEFAULT 'geral',
    andar_id      INT NOT NULL DEFAULT 1,
    tipo_minigame VARCHAR(100) NOT NULL,
    vitoria       BOOLEAN NOT NULL DEFAULT false,
    tempo_gasto   FLOAT DEFAULT 0.0,
    detalhes      JSONB DEFAULT '{}'::jsonb,
    cla_aluno     VARCHAR(100) DEFAULT 'Nenhum',
    timestamp     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE minigames_respostas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura de minigames" ON minigames_respostas;
DROP POLICY IF EXISTS "Insercao de minigames" ON minigames_respostas;
CREATE POLICY "Leitura de minigames"  ON minigames_respostas FOR SELECT USING (true);
CREATE POLICY "Insercao de minigames" ON minigames_respostas FOR INSERT WITH CHECK (true);
GRANT SELECT ON minigames_respostas TO anon, authenticated;
GRANT INSERT ON minigames_respostas TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE minigames_respostas_id_seq TO anon, authenticated;

-- 6. Corrigir policies do RANKING (antigas usavam auth.jwt() ->> 'nick' que sempre falhava)
ALTER TABLE rankinggeral ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica do ranking" ON rankinggeral;
DROP POLICY IF EXISTS "Insert autenticado" ON rankinggeral;
DROP POLICY IF EXISTS "Update proprio player" ON rankinggeral;
DROP POLICY IF EXISTS "Inserir score ranking" ON rankinggeral;
DROP POLICY IF EXISTS "Atualizar score ranking" ON rankinggeral;
CREATE POLICY "Leitura publica do ranking" ON rankinggeral FOR SELECT USING (true);
CREATE POLICY "Inserir score ranking"      ON rankinggeral FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar score ranking"    ON rankinggeral FOR UPDATE USING (true) WITH CHECK (true);
GRANT SELECT ON rankinggeral TO anon, authenticated;
GRANT INSERT, UPDATE ON rankinggeral TO anon, authenticated;

-- 7. Garantir policies abertas em RESPOSTAS (anon pode inserir)
ALTER TABLE respostas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura de respostas" ON respostas;
DROP POLICY IF EXISTS "Insercao de respostas" ON respostas;
DROP POLICY IF EXISTS "Exclusao de respostas" ON respostas;
CREATE POLICY "Leitura de respostas"  ON respostas FOR SELECT USING (true);
CREATE POLICY "Insercao de respostas" ON respostas FOR INSERT WITH CHECK (true);
CREATE POLICY "Exclusao de respostas" ON respostas FOR DELETE USING (true);
GRANT SELECT ON respostas TO anon, authenticated;
GRANT INSERT ON respostas TO anon, authenticated;

-- 8. Garantir policies em CLÃS (anon pode ler, auth pode modificar)
ALTER TABLE "Clas" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica de clas" ON "Clas";
DROP POLICY IF EXISTS "Inserir novo cla" ON "Clas";
DROP POLICY IF EXISTS "Atualizar cla" ON "Clas";
DROP POLICY IF EXISTS "Remover cla" ON "Clas";
CREATE POLICY "Leitura publica de clas" ON "Clas" FOR SELECT USING (true);
CREATE POLICY "Inserir novo cla"        ON "Clas" FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar cla"           ON "Clas" FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Remover cla"             ON "Clas" FOR DELETE USING (true);
GRANT SELECT ON "Clas" TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON "Clas" TO authenticated;

-- 9. Sessão geral padrão
INSERT INTO sessoes_escolas (id, nome, ativa)
VALUES ('geral', 'Geral (Padrão)', true)
ON CONFLICT (id) DO NOTHING;

-- Verificação final
SELECT 
  'respostas.tempo_resposta'      AS coluna, EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='respostas' AND column_name='tempo_resposta') AS ok
UNION ALL SELECT 'telemetria_gameplay', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='telemetria_gameplay')
UNION ALL SELECT 'minigames_respostas', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='minigames_respostas')
UNION ALL SELECT 'rankinggeral.insignias', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='rankinggeral' AND column_name='insignias');
