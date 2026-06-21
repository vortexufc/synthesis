-- Schema do banco de dados 
-- IMPORTANTE: Os nomes das colunas (question, options, answer) devem ser EXATAMENTE esses,
-- pois o DatabaseManager.gd e QuizManager.gd dependem dessas chaves para funcionar.

CREATE TABLE perguntas (
    id              SERIAL   PRIMARY KEY,
    question        TEXT     NOT NULL,                  -- Texto da pergunta
    options         JSONB    NOT NULL,                  -- Array JSON com as 4 alternativas
    answer          SMALLINT NOT NULL,                  -- Índice (0-3) da resposta correta em options
    andar_id        INT      NOT NULL DEFAULT 1,        -- Andar: 1=Biologia, 2=Química, 3=Física
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
