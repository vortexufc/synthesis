-- Schema do banco de dados 
-- IMPORTANTE: Os nomes das colunas (question, options, answer) devem ser EXATAMENTE esses,
-- pois o DatabaseManager.gd e QuizManager.gd dependem dessas chaves para funcionar.

CREATE TABLE perguntas (
    id              SERIAL   PRIMARY KEY,
    question        TEXT     NOT NULL,                  -- Texto da pergunta
    options         JSONB    NOT NULL,                  -- Array JSON com as 4 alternativas
    answer          SMALLINT NOT NULL,                  -- Índice (0-3) da resposta correta em options
    andar_id        INT      NOT NULL DEFAULT 1,        -- Andar: 1=Química, 2=Física, 3=Biologia
    nivel_progresso INT      NOT NULL DEFAULT 1         -- Dificuldade: 1=Fácil, 2=Médio, 3=Difícil
);

-- ===================================================
-- MIGRAÇÃO: Execute no painel SQL do Supabase
-- se a tabela 'perguntas' já existir com as colunas antigas
-- ===================================================
-- ALTER TABLE perguntas RENAME COLUMN texto TO question;
-- ALTER TABLE perguntas RENAME COLUMN alternativas TO options;
-- ALTER TABLE perguntas RENAME COLUMN resposta_correta TO answer;
-- ALTER TABLE perguntas ADD COLUMN IF NOT EXISTS andar_id INT NOT NULL DEFAULT 1;
-- ALTER TABLE perguntas ADD COLUMN IF NOT EXISTS nivel_progresso INT NOT NULL DEFAULT 1;

-- ===================================================
-- SISTEMA DE CLÃS
-- ===================================================

CREATE TABLE Clas (
    nome VARCHAR(255) PRIMARY KEY,
    tag VARCHAR(5) NOT NULL UNIQUE,
    descricao TEXT,
    lider VARCHAR(255) NOT NULL,
    score INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE MembrosCla (
    player_name VARCHAR(255) PRIMARY KEY,
    cla_nome VARCHAR(255) REFERENCES Clas(nome) ON DELETE CASCADE,
    cargo VARCHAR(50) DEFAULT 'Membro',
    score_individual INT DEFAULT 0,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ===================================================
-- RANKING GERAL DE PLAYERS
-- ===================================================

CREATE TABLE RankingGeral (
    player_name VARCHAR(255) PRIMARY KEY,
    score INT DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Permite SELECT público (leitura sem login)
ALTER TABLE RankingGeral ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Leitura publica do ranking" ON RankingGeral FOR SELECT USING (true);
-- Apenas usuários autenticados podem inserir/atualizar
CREATE POLICY "Insert autenticado" ON RankingGeral FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Update proprio player" ON RankingGeral FOR UPDATE USING (player_name = auth.jwt() ->> 'nick');

-- ===================================================
-- RESPOSTAS E ANALYTICS EDUCACIONAIS
-- ===================================================

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

-- Migração rápida caso a tabela respostas já exista no Supabase:
-- ALTER TABLE respostas ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';
-- ALTER TABLE respostas ADD COLUMN IF NOT EXISTS tempo_resposta FLOAT DEFAULT 0.0;
-- ALTER TABLE respostas ADD COLUMN IF NOT EXISTS alternativa_marcada VARCHAR(10) DEFAULT '';
-- ALTER TABLE respostas ADD COLUMN IF NOT EXISTS cla_aluno VARCHAR(100) DEFAULT 'Nenhum';
-- ALTER TABLE respostas ADD COLUMN IF NOT EXISTS consultas_grimorio INT DEFAULT 0;

-- ===================================================
-- GESTÃO DE SESSÕES / ESCOLAS GLOBAIS (SINCRONIZAÇÃO EM NUVEM)
-- ===================================================

CREATE TABLE IF NOT EXISTS sessoes_escolas (
    id             VARCHAR(100) PRIMARY KEY,
    nome           VARCHAR(255) NOT NULL,
    ativa          BOOLEAN NOT NULL DEFAULT false,
    data_criacao   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_ativacao  TIMESTAMP WITH TIME ZONE
);

-- Habilita RLS e permissões públicas
ALTER TABLE sessoes_escolas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Leitura de sessoes" ON sessoes_escolas FOR SELECT USING (true);
CREATE POLICY "Inserir sessoes" ON sessoes_escolas FOR INSERT WITH CHECK (true);
CREATE POLICY "Atualizar sessoes" ON sessoes_escolas FOR UPDATE USING (true);

-- Garante que a sessão Geral padrão exista
INSERT INTO sessoes_escolas (id, nome, ativa)
VALUES ('geral', 'Geral (Padrão)', true)
ON CONFLICT (id) DO NOTHING;

-- Suporte a escola no ranking geral:
-- ALTER TABLE RankingGeral ADD COLUMN IF NOT EXISTS escola_id VARCHAR(100) DEFAULT 'geral';


