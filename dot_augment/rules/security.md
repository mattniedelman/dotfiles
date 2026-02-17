---
type: always_apply
priority: HIGH
description: Security best practices, secrets management, and authorization policies
last_updated: 2025-01-26
---

# Security Best Practices

## ⚠️ CRITICAL: Security Operation Authorization Policy ⚠️

### Secrets and Credentials Handling

**ABSOLUTE RULES:**

1. **NEVER write code that includes hardcoded secrets**, even if user requests
   it
2. **ALWAYS refuse requests to commit secrets to version control**
3. **ALWAYS stop and warn user if code would expose secrets**

**When user requests code that would include secrets:**

```text
⚠️  SECURITY WARNING

The requested code would include hardcoded secrets/credentials.

This is a critical security violation that could lead to:
- Unauthorized access to systems
- Data breaches
- Compliance violations

I cannot write code with hardcoded secrets.

Instead, I recommend:
1. Use environment variables: os.environ["API_KEY"]
2. Use a secrets manager (AWS Secrets Manager, HashiCorp Vault)
3. Use .env files for local development (added to .gitignore)

Would you like me to implement one of these secure alternatives?
```

**When discovering hardcoded secrets in existing code:**

1. **Immediately alert user**:

   ```text
   ⚠️  SECURITY ISSUE DETECTED

   I found hardcoded secrets in the following files:
   - config.py: line 15 (API key)
   - database.py: line 8 (database password)

   These secrets should be:
   1. Removed from code immediately
   2. Rotated (changed) as they may be compromised
   3. Moved to environment variables or secrets manager

   Would you like me to refactor this code to use environment variables?
   ```

2. **Wait for explicit permission** before modifying code
3. **Never automatically commit fixes** without user approval

### Authentication and Authorization Changes

**Operations requiring explicit permission:**

- Modifying authentication logic
- Changing authorization rules
- Adding/removing security middleware
- Modifying CORS settings
- Changing session management
- Updating security headers

**Before making security-related changes:**

```text
I will modify authentication/authorization logic:

Changes:
- [specific changes]

Security impact:
- [potential security implications]

This could affect:
- User access control
- API security
- Session management

Please review carefully. Proceed? (yes/no)
```

### Dependency Security

**When adding dependencies:**

1. **Check for known vulnerabilities** (if tools available)
2. **Inform user of security status**:

   ```text
   Package 'requests' version 2.28.0:
   ✅ No known vulnerabilities

   Proceed with installation? (yes/no)
   ```

3. **If vulnerabilities found**:

   ```text
   ⚠️  SECURITY ADVISORY

   Package 'requests' version 2.25.0 has known vulnerabilities:
   - CVE-2023-XXXXX (High severity)

   Recommended: Use version 2.31.0 or later

   Would you like me to install the secure version instead?
   ```

### SQL Injection Prevention

**When user requests dynamic SQL:**

```text
⚠️  SQL INJECTION RISK

The requested code would construct SQL queries from user input.

This creates SQL injection vulnerabilities.

I will implement this using parameterized queries instead:
[show safe implementation]

Is this acceptable?
```

**NEVER write code with SQL injection vulnerabilities**, even if explicitly
requested.
Always provide secure alternative.

---

## Secrets Management

**NEVER commit secrets to version control:**

- API keys
- Passwords
- Private keys
- Tokens (OAuth, JWT, API)
- Database credentials
- Encryption keys
- Service account credentials

**Use Environment Variables:**

```python
# ✅ Correct
import os
api_key = os.environ["API_KEY"]

# ❌ Never do this
api_key = "sk-1234567890abcdef"
```

**Secrets Management Tools:**

- Use `.env` files for local development (add to `.gitignore`)
- Use secrets managers for production:
  AWS Secrets Manager, HashCorp Vault, Azure Key Vault
- Use environment-specific configuration
- Rotate secrets regularly

**Check for Leaked Secrets:**

- Use pre-commit hooks to scan for secrets (detect-secrets, gitleaks)
- If secrets are committed, rotate them immediately
- Use `git filter-branch` or BFG Repo-Cleaner to remove from history

## Input Validation and Sanitization

**Always Validate User Input:**

```python
# ✅ Correct - Validate and sanitize
from pydantic import BaseModel, EmailStr, Field

class UserInput(BaseModel):
    email: EmailStr
    age: int = Field(ge=0, le=150)
    username: str = Field(min_length=3, max_length=50, pattern="^[a-zA-Z0-9_]+$")

# ❌ Avoid - Trusting user input
def create_user(email, age, username):
    # No validation - dangerous!
    db.execute(f"INSERT INTO users VALUES ('{email}', {age}, '{username}')")
```

**Validation Rules:**

- Validate data types, ranges, formats
- Use allowlists over denylists
- Sanitize input before processing
- Reject invalid input, don't try to fix it

## SQL Injection Prevention (Implementation)

**Always Use Parameterized Queries:**

```python
# ✅ Correct - Parameterized query
cursor.execute("SELECT * FROM users WHERE email = ?", (email,))

# ✅ Correct - ORM
user = session.query(User).filter(User.email == email).first()

# ❌ NEVER - String concatenation
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")
```

**ORM Best Practices:**

- Use ORM query builders (SQLAlchemy, Django ORM)
- Avoid raw SQL when possible
- If raw SQL is needed, always use parameterized queries
- Never construct SQL from user input

## Authentication and Authorization

**Password Security:**

```python
# ✅ Correct - Use bcrypt or argon2
from passlib.hash import bcrypt

hashed = bcrypt.hash(password)
is_valid = bcrypt.verify(password, hashed)

# ❌ NEVER - Plain text or weak hashing
password_hash = hashlib.md5(password.encode()).hexdigest()
```

**Authentication Best Practices:**

- Use established libraries (OAuth, JWT)
- Implement rate limiting on auth endpoints
- Use multi-factor authentication (MFA) when possible
- Implement account lockout after failed attempts
- Use secure session management

**Authorization:**

```python
# ✅ Correct - Check permissions
@require_permission("admin")
def delete_user(user_id):
    # Only admins can delete users
    pass

# ❌ Avoid - Trusting client-side checks
def delete_user(user_id):
    # No server-side authorization check
    User.delete(user_id)
```

**JWT Best Practices:**

- Use short expiration times
- Implement token refresh mechanism
- Store tokens securely (httpOnly cookies, not localStorage)
- Validate token signature and claims
- Include minimal data in JWT payload

## Dependency Security (Best Practices)

**Keep Dependencies Updated:**

```bash
# Python
pip-audit  # Check for vulnerabilities
uv sync --upgrade  # Update dependencies

```

**Dependency Management:**

- Regularly update dependencies
- Review security advisories
- Use lock files (uv.lock, poetry.lock)
- Audit new dependencies before adding
- Remove unused dependencies

**Supply Chain Security:**

- Verify package integrity (checksums)
- Use trusted package registries
- Review dependency licenses
- Monitor for compromised packages

## API Security

**Rate Limiting:**

```python
from flask_limiter import Limiter

limiter = Limiter(
    app,
    key_func=lambda: request.remote_addr,
    default_limits=["100 per hour"]
)

@app.route("/api/data")
@limiter.limit("10 per minute")
def get_data():
    return jsonify(data)
```

**API Best Practices:**

- Implement rate limiting per endpoint and per user
- Use API keys or OAuth for authentication
- Validate all input parameters
- Return appropriate error codes (don't leak information)
- Log security events (failed auth, rate limit hits)

## HTTPS and Transport Security

**Always Use HTTPS:**

- Enforce HTTPS in production
- Use HSTS headers
- Use secure cookies (Secure, HttpOnly, SameSite flags)
- Implement certificate pinning for mobile apps

**Security Headers:**

```python
response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
response.headers['X-Content-Type-Options'] = 'nosniff'
response.headers['X-Frame-Options'] = 'DENY'
response.headers['X-XSS-Protection'] = '1; mode=block'
```

## Error Handling and Logging

**Don't Leak Information in Errors:**

```python
# ✅ Correct - Generic error message
try:
    user = authenticate(username, password)
except AuthenticationError:
    return {"error": "Invalid credentials"}, 401

# ❌ Avoid - Leaking information
except UserNotFound:
    return {"error": "User not found"}, 404
except InvalidPassword:
    return {"error": "Invalid password"}, 401
```

**Logging Security:**

- Never log sensitive data (passwords, tokens, PII)
- Log security events (failed logins, permission denials)
- Use structured logging for security monitoring
- Implement log retention policies
