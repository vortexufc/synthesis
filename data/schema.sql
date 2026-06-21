-- Schema do banco de dados 

CREATE TABLE perguntas (
    id SERIAL PRIMARY KEY,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    answer SMALLINT NOT NULL,
    andar_id INTEGER NOT NULL,
    nivel_progresso INTEGER DEFAULT 1
);

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
