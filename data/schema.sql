-- Schema do banco de dados 

CREATE TABLE Perguntas (
    id SERIAL PRIMARY KEY,
    texto TEXT NOT NULL,
    alternativas JSONB NOT NULL,
    resposta_correta SMALLINT NOT NULL
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



