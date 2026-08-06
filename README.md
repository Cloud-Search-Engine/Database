# CloudSearch Database

Canonical **PostgreSQL + pgvector** schema for Cloud Search Engine. Backend and Ingestion read/write these tables; they do not own the migrations.

## What’s in this repo

| Path | Purpose |
| --- | --- |
| `migrations/001_init.sql` | Extensions, tables, indexes |
| `Makefile` | `make apply` / `make reset` against `DATABASE_URL` |
| `seeds/` | Reserved for SQL/JSON seed fixtures (optional) |

### Schema overview

| Table | Role |
| --- | --- |
| `documents` | Full documentation pages + provider/service metadata |
| `chunks` | Searchable units; optional `embedding vector(1536)` |
| `corpus_stats` | BM25 N / avgdl |
| `term_stats` | Per-term document frequency (BM25 IDF) |
| `ingestion_jobs` | Optional async job tracking |

Extensions: `pgcrypto`, `pg_trgm`, `vector` (HNSW index on embeddings).

## Prerequisites

- PostgreSQL **16+** with **pgvector** (local: `pgvector/pgvector:pg16` image)
- `psql` client for manual apply

## How to start (Docker — recommended locally)

From the parent `Cloud_Search_Engine` folder, compose mounts this migration on first boot:

```bash
docker compose up -d postgres
# applies Database/migrations/001_init.sql via /docker-entrypoint-initdb.d
```

Reset from scratch:

```bash
docker compose down -v
docker compose up -d postgres
```

## How to start (manual apply)

```bash
export DATABASE_URL=postgres://cloudsearch:cloudsearch@localhost:5432/cloudsearch?sslmode=disable
make apply
```

Or:

```bash
psql "$DATABASE_URL" -f migrations/001_init.sql
```

## AWS / RDS

1. Provision Postgres with Terraform (`Terraform` repo).
2. Ensure `vector` and `pg_trgm` are installable on the instance.
3. Apply:

```bash
psql "$DATABASE_URL" -f migrations/001_init.sql
```

## Ownership boundary

| Concern | Owner |
| --- | --- |
| Schema / migrations | **This repo** |
| Search / RAG reads | Backend |
| Upsert / embed / BM25 stats rebuild | Ingestion |
| Managed Postgres instance | Terraform (RDS) |
