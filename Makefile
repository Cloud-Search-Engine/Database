.PHONY: apply reset

DATABASE_URL ?= postgres://cloudsearch:cloudsearch@localhost:5432/cloudsearch?sslmode=disable

apply:
	psql "$(DATABASE_URL)" -f migrations/001_init.sql

reset:
	psql "$(DATABASE_URL)" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	$(MAKE) apply
