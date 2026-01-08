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

### Dirty Reads

Dirty Reads do not happen in PostgreSQL even with `READ UNCOMMITTED` isolation level.

PostgreSQL uses a Multiversion Concurrency Control (MVCC) architecture, which naturally prevents dirty reads

### Non-Repeatable Reads

In Terminal 1, run the following SQL:

```sql
BEGIN;

SELECT * FROM accounts WHERE name = 'Helen';
```

Switch to Terminal 2 and run the following SQL:

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE name = 'Helen';

COMMIT;
```

Switch to Terminal 1 and run the following SQL:

```sql
SELECT * FROM accounts WHERE name = 'Helen';

COMMIT;
```

Second `SELECT` in Terminal 1 returned `900` which means **the data changed mid-transaction**.

By default PostgreSQL uses `READ COMMITTED` isolation level which does not prevent **non-repeatable reads**.

What also can be noticed that if two transactions update the same row the second transaction will have to wait for the first transaction to finish and then it will read the updated data.

#### Preventing Non-Repeatable Reads

`REPEATABLE READ` isolation level prevents non-repeatable reads.

In Terminal 1, run the following SQL:

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Helen';
```

In Terminal 2, run the following SQL:

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Helen';
```

`UPDATE` in Terminal 2 **will freeze the transaction** and wait for the transaction in Terminal 1 to finish.

Cancel the transaction in Terminal 1 to continue transaction in Terminal 2.

```sql
ROLLBACK;
```

Or `COMMIT` the transaction in Terminal 1 to get an error in Terminal 2.

```sql
COMMIT;
```

In Terminal 2:

```
ERROR:  could not serialize access due to concurrent update
```

