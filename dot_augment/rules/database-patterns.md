---
type: agent_requested
description: Database design patterns, schema design, migrations, query optimization, ORM usage, connection pooling, and transaction management
---

# Database Patterns

## Schema Design Principles

**Normalization:**
- Use 3rd Normal Form (3NF) as baseline
- Denormalize strategically for performance (read-heavy workloads)
- Document denormalization decisions

**Primary Keys:**
```sql
-- ✅ Correct - Use UUIDs or auto-incrementing integers
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alternative: Auto-incrementing integer
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ❌ Avoid - Natural keys as primary keys
CREATE TABLE users (
    email VARCHAR(255) PRIMARY KEY  -- Don't use natural keys
);
```

**Foreign Keys:**
```sql
-- ✅ Correct - Always define foreign key constraints
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Consider ON DELETE behavior:
-- CASCADE: Delete related records
-- SET NULL: Set foreign key to NULL
-- RESTRICT: Prevent deletion if references exist
```

**Indexes:**
```sql
-- ✅ Create indexes for:
-- 1. Foreign keys
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- 2. Frequently queried columns
CREATE INDEX idx_users_email ON users(email);

-- 3. Composite indexes for multi-column queries
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- 4. Partial indexes for filtered queries
CREATE INDEX idx_active_users ON users(email) WHERE active = true;

-- ❌ Avoid over-indexing (slows writes, uses storage)
```

**Data Types:**
```sql
-- ✅ Use appropriate data types
email VARCHAR(255)           -- Not TEXT for bounded strings
age INTEGER                  -- Not VARCHAR for numbers
price DECIMAL(10, 2)         -- Not FLOAT for money
is_active BOOLEAN            -- Not INTEGER for flags
created_at TIMESTAMP         -- Not VARCHAR for dates
metadata JSONB               -- Use JSONB for flexible data

-- ❌ Avoid
email TEXT                   -- Too generic
age VARCHAR(10)              -- Wrong type
price FLOAT                  -- Precision issues
is_active INTEGER            -- Not semantic
```

## Migration Management

**Migration Best Practices:**
```python
# Use Alembic for Python/SQLAlchemy
# migrations/versions/001_create_users_table.py

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.UUID(), primary_key=True),
        sa.Column('email', sa.String(255), nullable=False, unique=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
    )
    op.create_index('idx_users_email', 'users', ['email'])

def downgrade():
    op.drop_index('idx_users_email')
    op.drop_table('users')
```

**Migration Guidelines:**
- **Always reversible**: Implement both `upgrade()` and `downgrade()`
- **Atomic**: Each migration should be a single logical change
- **Tested**: Test migrations on copy of production data
- **Backward compatible**: Don't break running code during deployment
- **Data migrations**: Separate schema changes from data changes

**Zero-Downtime Migrations:**
```python
# Step 1: Add new column (nullable)
def upgrade():
    op.add_column('users', sa.Column('full_name', sa.String(255), nullable=True))

# Step 2: Backfill data (separate migration)
def upgrade():
    op.execute("""
        UPDATE users 
        SET full_name = first_name || ' ' || last_name
        WHERE full_name IS NULL
    """)

# Step 3: Make column non-nullable (separate migration)
def upgrade():
    op.alter_column('users', 'full_name', nullable=False)

# Step 4: Remove old columns (separate migration, after deployment)
def upgrade():
    op.drop_column('users', 'first_name')
    op.drop_column('users', 'last_name')
```

## Query Optimization

**Use Indexes Effectively:**
```python
# ✅ Correct - Query uses index
users = session.query(User).filter(User.email == email).first()

# ❌ Avoid - Function on indexed column prevents index usage
users = session.query(User).filter(func.lower(User.email) == email.lower()).all()

# ✅ Better - Use functional index or store lowercase
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

**Avoid N+1 Queries:**
```python
# ❌ Avoid - N+1 query problem
users = session.query(User).all()
for user in users:
    print(user.orders)  # Separate query for each user

# ✅ Correct - Eager loading
users = session.query(User).options(joinedload(User.orders)).all()
for user in users:
    print(user.orders)  # No additional queries
```

**Select Only Needed Columns:**
```python
# ❌ Avoid - Selecting all columns
users = session.query(User).all()

# ✅ Correct - Select specific columns
users = session.query(User.id, User.email).all()

# ✅ Even better for large result sets
users = session.query(User.id, User.email).yield_per(1000)
```

**Use Query Limits:**
```python
# ✅ Always use limits for potentially large result sets
recent_orders = session.query(Order).order_by(Order.created_at.desc()).limit(100).all()

# ✅ Implement pagination
def get_orders(page: int = 1, page_size: int = 20):
    offset = (page - 1) * page_size
    return session.query(Order).offset(offset).limit(page_size).all()
```

**Analyze Query Performance:**
```sql
-- Use EXPLAIN ANALYZE to understand query performance
EXPLAIN ANALYZE
SELECT u.email, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.email
HAVING COUNT(o.id) > 5;
```

## ORM Usage Patterns

**SQLAlchemy Best Practices:**
```python
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship, declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    orders = relationship("Order", back_populates="user", lazy="select")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"

class Order(Base):
    __tablename__ = 'orders'

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    total = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="orders")
```

**Lazy Loading Strategies:**
```python
# select (default): Load on access (N+1 risk)
orders = relationship("Order", lazy="select")

# joined: Eager load with JOIN
orders = relationship("Order", lazy="joined")

# subquery: Eager load with subquery
orders = relationship("Order", lazy="subquery")

# dynamic: Return query object (for large collections)
orders = relationship("Order", lazy="dynamic")

# Override per-query
users = session.query(User).options(joinedload(User.orders)).all()
```

**Bulk Operations:**
```python
# ✅ Correct - Bulk insert
session.bulk_insert_mappings(
    User,
    [
        {"email": "user1@example.com"},
        {"email": "user2@example.com"},
    ]
)

# ✅ Correct - Bulk update
session.bulk_update_mappings(
    User,
    [
        {"id": 1, "email": "updated1@example.com"},
        {"id": 2, "email": "updated2@example.com"},
    ]
)

# ❌ Avoid - Individual inserts in loop
for email in emails:
    user = User(email=email)
    session.add(user)
    session.commit()  # Don't commit in loop!
```

## Connection Pooling

**Configure Connection Pool:**
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    "postgresql://user:pass@localhost/db",
    poolclass=QueuePool,
    pool_size=10,              # Number of connections to maintain
    max_overflow=20,           # Additional connections when pool is full
    pool_timeout=30,           # Seconds to wait for connection
    pool_recycle=3600,         # Recycle connections after 1 hour
    pool_pre_ping=True,        # Verify connections before using
)
```

**Connection Pool Best Practices:**
- Size pool based on concurrent workload
- Use `pool_pre_ping=True` to handle stale connections
- Recycle connections periodically
- Monitor pool usage and adjust sizing
- Use connection pooling at application level, not per-request

**Context Manager Pattern:**
```python
from contextlib import contextmanager

@contextmanager
def get_db_session():
    session = Session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Usage
with get_db_session() as session:
    user = session.query(User).filter(User.id == user_id).first()
    user.email = new_email
```

## Transaction Management

**ACID Principles:**
- **Atomicity**: All operations succeed or all fail
- **Consistency**: Database remains in valid state
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed changes persist

**Transaction Patterns:**
```python
# ✅ Correct - Explicit transaction
from sqlalchemy.orm import Session

session = Session(engine)
try:
    user = User(email="user@example.com")
    session.add(user)

    order = Order(user_id=user.id, total=100.00)
    session.add(order)

    session.commit()
except Exception as e:
    session.rollback()
    raise
finally:
    session.close()

# ✅ Better - Context manager
with Session(engine) as session:
    with session.begin():
        user = User(email="user@example.com")
        session.add(user)

        order = Order(user_id=user.id, total=100.00)
        session.add(order)
```

**Isolation Levels:**
```python
from sqlalchemy import create_engine

# Set isolation level
engine = create_engine(
    "postgresql://user:pass@localhost/db",
    isolation_level="REPEATABLE READ"
)

# Isolation levels (from least to most strict):
# - READ UNCOMMITTED
# - READ COMMITTED (default for most databases)
# - REPEATABLE READ
# - SERIALIZABLE
```

**Optimistic Locking:**
```python
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    email = Column(String(255))
    version = Column(Integer, default=1, nullable=False)

    __mapper_args__ = {
        "version_id_col": version
    }

# SQLAlchemy automatically handles version checking
user = session.query(User).filter(User.id == 1).first()
user.email = "new@example.com"
session.commit()  # Raises StaleDataError if version changed
```

## Database Performance Monitoring

**Key Metrics to Track:**
- Query execution time (slow query log)
- Connection pool usage
- Cache hit ratio
- Index usage statistics
- Table bloat
- Lock contention

**Slow Query Logging:**
```sql
-- PostgreSQL: Enable slow query log
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1s
SELECT pg_reload_conf();

-- Analyze slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

**Index Usage Analysis:**
```sql
-- Find unused indexes
SELECT schemaname, tablename, indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexrelname NOT LIKE '%_pkey';

-- Find missing indexes
SELECT schemaname, tablename, seq_scan, seq_tup_read
FROM pg_stat_user_tables
WHERE seq_scan > 1000
ORDER BY seq_tup_read DESC;
```

## Database Best Practices

**Backup and Recovery:**
- Automated daily backups
- Test restore procedures regularly
- Point-in-time recovery capability
- Backup retention policy

**Security:**
- Use least-privilege database users
- Never use root/admin for application
- Encrypt connections (SSL/TLS)
- Encrypt sensitive data at rest
- Audit database access

**Maintenance:**
- Regular VACUUM (PostgreSQL)
- Update statistics regularly
- Monitor table bloat
- Archive old data
- Plan for database growth

**Development Practices:**
- Use migrations for all schema changes
- Test migrations on production-like data
- Never modify production database manually
- Use separate databases for dev/staging/production
- Document schema design decisions


