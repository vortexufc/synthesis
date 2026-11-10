-- ==============================================================================
-- SYNTHESIS — SCHEMA COMPLETO E CORRIGIDO DO SUPABASE (POSTGRESQL)
-- IDEMPOTENTE: pode rodar quantas vezes quiser sem perder dados existentes.
-- Execute no SQL Editor do painel do Supabase: https://supabase.com/dashboard
-- ==============================================================================

-- ============================================================
-- 1. PERGUNTAS (QUIZ)
-- ============================================================
CREATE TABLE IF NOT EXISTS perguntas (
    id              SERIAL   PRIMARY KEY,
    question        TEXT     NOT NULL,
    options         JSONB    NOT NULL,
    answer          SMALLINT NOT NULL,
    andar_id        INT      NOT NULL DEFAULT 1,
    nivel_progresso INT      NOT NULL DEFAULT 1
);

ALTER TABLE perguntas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica de perguntas" ON perguntas;
CREATE POLICY "Leitura publica de perguntas" ON perguntas FOR SELECT USING (true);
DROP POLICY IF EXISTS "Escrita autenticada de perguntas" ON perguntas;
CREATE POLICY "Escrita autenticada de perguntas" ON perguntas FOR ALL USING (true) WITH CHECK (true);

-- Garante acesso da API REST (anon e authenticated)
GRANT SELECT ON perguntas TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON perguntas TO authenticated;


-- ============================================================
-- 2. RESPOSTAS E ANALYTICS EDUCACIONAIS
-- ============================================================
CREATE TABLE IF NOT EXISTS respostas (
    id                  BIGSERIAL PRIMARY KEY,
    pergunta_id         INT NOT NULL,
    acertou             BOOLEAN NOT NULL,
    andar_id            INT NOT NULL DEFAULT 1,
    aluno_nick          VARCHAR(255) NOT NULL,
    escola_id           VARCHAR(100) DEFAULT 'geral',
    tempo_resposta      FLOAT DEFAULT 0.0,
    alternativa_marcada VARCHAR(10) DEFAULT '',
    cla_aluno           VARCHAR(100) DEFAULT 'Nenhum',
    consultas_grimorio  INT DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Adiciona colunas que podem estar faltando (banco legado)
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS tempo_resposta FLOAT DEFAULT 0.0;
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS alternativa_marcada VARCHAR(10) DEFAULT '';
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS cla_aluno VARCHAR(100) DEFAULT 'Nenhum';
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS consultas_grimorio INT DEFAULT 0;
ALTER TABLE respostas ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE respostas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura de respostas" ON respostas;
CREATE POLICY "Leitura de respostas" ON respostas FOR SELECT USING (true);
DROP POLICY IF EXISTS "Insercao de respostas" ON respostas;
CREATE POLICY "Insercao de respostas" ON respostas FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Exclusao de respostas" ON respostas;
CREATE POLICY "Exclusao de respostas" ON respostas FOR DELETE USING (true);

GRANT SELECT ON respostas TO anon, authenticated;
GRANT INSERT ON respostas TO anon, authenticated;
GRANT DELETE ON respostas TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE respostas_id_seq TO anon, authenticated;


-- ============================================================
-- 3. RANKING GERAL DE PLAYERS
-- ============================================================
CREATE TABLE IF NOT EXISTS RankingGeral (
    player_name   VARCHAR(255) PRIMARY KEY,
    score         INT DEFAULT 0,
    score_diario  INT DEFAULT 0,
    score_semanal INT DEFAULT 0,
    score_mensal  INT DEFAULT 0,
    escola_id     VARCHAR(100) DEFAULT 'geral',
    insignias     JSONB DEFAULT '[]'::jsonb,
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS score_diario  INT DEFAULT 0;
ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS score_semanal INT DEFAULT 0;
ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS score_mensal  INT DEFAULT 0;
ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS escola_id     VARCHAR(100) DEFAULT 'geral';
ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS insignias     JSONB DEFAULT '[]'::jsonb;
ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS updated_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE RankingGeral ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica do ranking" ON RankingGeral;
DROP POLICY IF EXISTS "Insert autenticado" ON RankingGeral;
DROP POLICY IF EXISTS "Update proprio player" ON RankingGeral;
DROP POLICY IF EXISTS "Inserir score ranking" ON RankingGeral;
DROP POLICY IF EXISTS "Atualizar score ranking" ON RankingGeral;

CREATE POLICY "Leitura publica do ranking"
  ON RankingGeral FOR SELECT USING (true);

CREATE POLICY "Inserir score ranking"
  ON RankingGeral FOR INSERT WITH CHECK (true);

CREATE POLICY "Atualizar score ranking"
  ON RankingGeral FOR UPDATE USING (true) WITH CHECK (true);

GRANT SELECT ON RankingGeral TO anon, authenticated;
GRANT INSERT, UPDATE ON RankingGeral TO anon, authenticated;


-- ============================================================
-- 4. SISTEMA DE CLÃS E MEMBROS
-- ============================================================
CREATE TABLE IF NOT EXISTS Clas (
    nome        VARCHAR(255) PRIMARY KEY,
    tag         VARCHAR(5) NOT NULL UNIQUE,
    descricao   TEXT,
    lider       VARCHAR(255) NOT NULL,
    score       INT DEFAULT 0,
    escola_id   VARCHAR(100) DEFAULT 'geral',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE Clas ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';
ALTER TABLE Clas ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE Clas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica de clas" ON Clas;
DROP POLICY IF EXISTS "Inserir novo cla" ON Clas;
DROP POLICY IF EXISTS "Atualizar cla" ON Clas;
DROP POLICY IF EXISTS "Remover cla" ON Clas;

CREATE POLICY "Leitura publica de clas"  ON Clas FOR SELECT USING (true);
CREATE POLICY "Inserir novo cla"         ON Clas FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar cla"            ON Clas FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Remover cla"             ON Clas FOR DELETE USING (true);

GRANT SELECT ON Clas TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON Clas TO authenticated;


CREATE TABLE IF NOT EXISTS MembrosCla (
    player_name      VARCHAR(255) PRIMARY KEY,
    cla_nome         VARCHAR(255) REFERENCES Clas(nome) ON DELETE CASCADE,
    cargo            VARCHAR(50) DEFAULT 'Membro',
    score_individual INT DEFAULT 0,
    escola_id        VARCHAR(100) DEFAULT 'geral',
    joined_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE MembrosCla ADD COLUMN IF NOT EXISTS escola_id  VARCHAR(100) DEFAULT 'geral';
ALTER TABLE MembrosCla ADD COLUMN IF NOT EXISTS joined_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE MembrosCla ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura publica de membros" ON MembrosCla;
DROP POLICY IF EXISTS "Inserir membro cla" ON MembrosCla;
DROP POLICY IF EXISTS "Atualizar membro cla" ON MembrosCla;
DROP POLICY IF EXISTS "Remover membro cla" ON MembrosCla;

CREATE POLICY "Leitura publica de membros" ON MembrosCla FOR SELECT USING (true);
CREATE POLICY "Inserir membro cla"         ON MembrosCla FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar membro cla"       ON MembrosCla FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Remover membro cla"        ON MembrosCla FOR DELETE USING (true);

GRANT SELECT ON MembrosCla TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON MembrosCla TO authenticated;


-- ============================================================
-- 5. TELEMETRIA DE GAMEPLAY (TEMPO DE JOGO, MORTES, POÇÕES)
-- ============================================================
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


-- ============================================================
-- 6. ANALYTICS DE MINIGAMES (MEMÓRIA, LIGAR PARES, MURAL)
-- ============================================================
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


-- ============================================================
-- 7. SESSÕES / ESCOLAS (GESTÃO PEDAGÓGICA)
-- ============================================================
CREATE TABLE IF NOT EXISTS sessoes_escolas (
    id             VARCHAR(100) PRIMARY KEY,
    nome           VARCHAR(255) NOT NULL,
    ativa          BOOLEAN NOT NULL DEFAULT false,
    data_criacao   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_ativacao  TIMESTAMP WITH TIME ZONE
);

ALTER TABLE sessoes_escolas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Leitura de sessoes" ON sessoes_escolas;
DROP POLICY IF EXISTS "Inserir sessoes" ON sessoes_escolas;
DROP POLICY IF EXISTS "Atualizar sessoes" ON sessoes_escolas;
DROP POLICY IF EXISTS "Excluir sessoes" ON sessoes_escolas;

CREATE POLICY "Leitura de sessoes"  ON sessoes_escolas FOR SELECT USING (true);
CREATE POLICY "Inserir sessoes"     ON sessoes_escolas FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar sessoes"   ON sessoes_escolas FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Excluir sessoes"     ON sessoes_escolas FOR DELETE USING (true);

GRANT SELECT ON sessoes_escolas TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON sessoes_escolas TO authenticated;

-- Garante que sessão Geral padrão exista
INSERT INTO sessoes_escolas (id, nome, ativa)
VALUES ('geral', 'Geral (Padrão)', true)
ON CONFLICT (id) DO NOTHING;
