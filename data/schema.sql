-- Schema do banco de dados 

CREATE TABLE Perguntas (
    id SERIAL PRIMARY KEY,
    texto TEXT NOT NULL,
    alternativas JSONB NOT NULL,
    resposta_correta SMALLINT NOT NULL
);


