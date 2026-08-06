-- CloudSearch canonical schema (owned by the Database repo).
-- Applied by the postgres container on first boot via /docker-entrypoint-initdb.d

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

CREATE TABLE IF NOT EXISTS documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     TEXT NOT NULL UNIQUE,
    provider        TEXT NOT NULL,
    service         TEXT NOT NULL,
    category        TEXT NOT NULL,
    document_type   TEXT NOT NULL DEFAULT 'developer_documentation',
    title           TEXT NOT NULL,
    source_url      TEXT NOT NULL,
    version         TEXT NOT NULL DEFAULT 'current',
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chunks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id        TEXT NOT NULL UNIQUE,
    document_id     TEXT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    provider        TEXT NOT NULL,
    service         TEXT NOT NULL,
    category        TEXT NOT NULL,
    title           TEXT NOT NULL,
    heading         TEXT,
    section         TEXT,
    source_url      TEXT NOT NULL,
    content         TEXT NOT NULL,
    token_count     INT NOT NULL DEFAULT 0,
    position        INT NOT NULL DEFAULT 0,
    embedding       vector(1536),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS corpus_stats (
    id              INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    document_count  INT NOT NULL DEFAULT 0,
    avg_doc_length  DOUBLE PRECISION NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS term_stats (
    term            TEXT PRIMARY KEY,
    document_freq   INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS ingestion_jobs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     TEXT NOT NULL,
    s3_key          TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending',
    attempts        INT NOT NULL DEFAULT 0,
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_provider ON documents(provider);
CREATE INDEX IF NOT EXISTS idx_documents_service ON documents(service);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_chunks_document_id ON chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_chunks_provider ON chunks(provider);
CREATE INDEX IF NOT EXISTS idx_chunks_service ON chunks(service);
CREATE INDEX IF NOT EXISTS idx_chunks_category ON chunks(category);
CREATE INDEX IF NOT EXISTS idx_chunks_content_trgm ON chunks USING GIN (content gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_chunks_title_trgm ON chunks USING GIN (title gin_trgm_ops);
-- HNSW index for cosine similarity (safe on sparse/empty tables vs IVFFlat).
CREATE INDEX IF NOT EXISTS idx_chunks_embedding ON chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_ingestion_jobs_status ON ingestion_jobs(status);
CREATE INDEX IF NOT EXISTS idx_ingestion_jobs_document_id ON ingestion_jobs(document_id);

INSERT INTO corpus_stats (id, document_count, avg_doc_length)
VALUES (1, 0, 0)
ON CONFLICT (id) DO NOTHING;
