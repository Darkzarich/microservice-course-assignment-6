# Assignment #6 - PostgreSQL Transaction Isolation

This is "Microservices and High-Load" course 6th homework assignment.

The goal of this assignment is to try and see different isolation levels in PostgreSQL.

## Requirements

- Docker
- Docker Compose (for simplicity)

## How to run

1. Run postgres container using Docker Compose:

```bash
docker compose up -d
```

2. Connect to PostgreSQL inside the container in two separate terminals:

```bash
# Terminal 1
docker compose exec -it postgres psql -U admin -d testdb

# Terminal 2
docker compose exec -it postgres psql -U admin -d testdb
```

From this point on, "steps" are to be executed in each terminal.

## Steps
