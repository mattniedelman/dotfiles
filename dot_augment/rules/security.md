---
type: always_apply
---

# Security Best Practices

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
- Use secrets managers for production: AWS Secrets Manager, HashiCorp Vault, Azure Key Vault
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

## SQL Injection Prevention

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

## Cross-Site Scripting (XSS) Prevention

**Escape Output:**
```python
# ✅ Correct - Framework handles escaping
return render_template("profile.html", username=username)

# ❌ Avoid - Manual HTML construction
return f"<div>Welcome {username}</div>"  # Vulnerable to XSS
```

**Content Security Policy:**
```python
# Add CSP headers
@app.after_request
def add_security_headers(response):
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    return response
```

**Best Practices:**
- Use framework templating engines (Jinja2, React)
- Never use `innerHTML` with user data
- Sanitize rich text input (use libraries like bleach)
- Set appropriate Content-Type headers

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

## Dependency Security

**Keep Dependencies Updated:**
```bash
# Python
pip-audit  # Check for vulnerabilities
uv sync --upgrade  # Update dependencies

# JavaScript
npm audit
npm audit fix
```

**Dependency Management:**
- Regularly update dependencies
- Review security advisories
- Use lock files (uv.lock, package-lock.json)
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

