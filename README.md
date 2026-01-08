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

The database will have some prepared tables and data.
From this point on, "steps" are to be executed in each terminal.

## Steps

Detailed step-by-step descriptions how different read phenomena occur and how different isolation levels affect them.

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

What also can be noticed that if two transactions update the same row the second transaction will have to wait for the first transaction to finish and then it will read the updated data if it was updated or the original data if it was not.

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

### Phantom Reads

In Terminal 1, run the following SQL:

```sql
BEGIN;
-- Will return 0 because no rows
SELECT COUNT(*) FROM transaction_logs WHERE account_id = 1;
```

In Terminal 2, run the following SQL:

```sql
BEGIN;
INSERT INTO transaction_logs (account_id, description, amount)
VALUES (1, 'Transfer fee', 5);
COMMIT;
```

In Terminal 1:

```sql
SELECT COUNT(*) FROM transaction_logs WHERE account_id = 1;
COMMIT;
```

The last `SELECT` in Terminal 1 returned `1` which means **the row appeared out of nowhere mid-transaction**.

#### Preventing Phantom Reads

`SERIALIZABLE` isolation level prevents phantom reads.

Repeat previous steps but use `SERIALIZABLE` isolation level.

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

Now the last `SELECT` still returns `1` even though the `INSERT` was committed.

It's important to note that `SERIALIZABLE` isolation level **doesn't merely lock the specific rows you modify it also tracks the reads your transaction performs to detect logical dependencies**.

This allows it to catch "write skew"—a scenario where two concurrent transactions read a consistent state (e.g., verifying that the total balance across two accounts is sufficient) and then make diverging changes to different rows based on that shared information.

Even though the updated rows (Max and Helen) are distinct, PostgreSQL detects that the combined outcome violates the integrity constraint implied by the initial reads, forcing one transaction to fail to ensure data consistency.

```sql
-- Terminal 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT sum(balance) FROM accounts WHERE name IN ('Max', 'Helen');
UPDATE accounts SET balance = 400 WHERE name = 'Max';
-- change to Terminal 2
COMMIT;

-- Terminal 2
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT sum(balance) FROM accounts WHERE name IN ('Max', 'Helen');
UPDATE accounts SET balance = 400 WHERE name = 'Helen';
COMMIT;
-- change to Terminal 1
```

Terminal 1 will fail with the following error:

```
ERROR:  could not serialize access due to read/write dependencies among transactions
```

If the used isolation level was `REPEATABLE READ` instead of `SERIALIZABLE` the **transaction would have succeeded** which may have not been what you wanted.
