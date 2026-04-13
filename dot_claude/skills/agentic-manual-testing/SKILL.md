---
name: agentic-manual-testing
description: Use when automated tests pass but you need to verify the feature actually works - manual testing via code execution, curl, browser automation
---

# Agentic Manual Testing

Automated tests passing ≠ feature works.
Manual testing catches what tests miss.

**Inspired by:** Simon Willison's pattern of having agents manually test their
own code using `python -c`, `curl`, and browser automation tools.

## Quick Reference

| Code Type | Manual Test Method |
|-----------|-------------------|
| Python library | `python -c "from module import func; print(func(edge_case))"` |
| CLI tool | Run with various inputs, edge cases |
| JSON API | `curl -X POST url -d '{"data": "test"}'` |
| Web UI | Playwright or browser automation |
| Any verification | Write to `/tmp` then execute |

## When to Use

**After automated tests pass, before claiming "feature complete":**

- Complex UI interactions that tests don't cover
- Integration points between systems
- Edge cases in user-facing workflows
- Visual verification (does it look right?)
- API responses with complex structures

## Process

### 1. Identify Testable Truths

What must be TRUE for the feature to work?

```text
Goal: "User authentication"
Truths:
- Valid credentials return JWT token
- Invalid credentials return 401
- Token works for protected routes
- Expired token is rejected
```

### 2. Execute Verification

Run commands that prove each truth:

```bash
# Test auth endpoint
curl -X POST http://localhost:8000/auth/login \
 -H "Content-Type: application/json" \
 -d '{"username": "test", "password": "test123"}' | jq

# Test with invalid creds
curl -X POST http://localhost:8000/auth/login \
 -H "Content-Type: application/json" \
 -d '{"username": "test", "password": "wrong"}' -w "\n%{http_code}"
```

### 3. Capture Evidence

Show the actual output, don't just describe it.

### 4. Fix with TDD if Issues Found

If manual testing reveals problems:

1. Write a failing test that reproduces the issue
2. Fix the code
3. Verify test passes
4. Re-run manual test

## Testing Patterns by Type

### Python Libraries

```bash
# Quick function test
python -c "from mylib import parse; print(parse(''))"        # Empty input
python -c "from mylib import parse; print(parse('a'*10000))" # Large input
python -c "from mylib import parse; print(parse(None))"      # None

# Interactive exploration
python -c "
from mylib import Client
c = Client()
result = c.fetch_data()
print(f'Type: {type(result)}')
print(f'Length: {len(result)}')
print(f'Sample: {result[:3]}')
"
```

### JSON APIs

```bash
# Start server in background
uvicorn app:app --port 8000 &

# Test endpoints
curl http://localhost:8000/api/items | jq '.'
curl http://localhost:8000/api/items/1 | jq '.'
curl -X POST http://localhost:8000/api/items \
 -H "Content-Type: application/json" \
 -d '{"name": "test"}' | jq '.'

# Check status codes
curl -w "\nStatus: %{http_code}\n" http://localhost:8000/api/notfound
```

### CLI Tools

```bash
# Test help
./mytool --help

# Test with various inputs
echo "test input" | ./mytool
./mytool --verbose input.txt
./mytool --format json input.txt | jq '.'

# Edge cases
./mytool ""                        # Empty
./mytool /nonexistent              # Missing file
./mytool <(echo "streaming input") # Process substitution
```

### Exploratory Testing

Tell the agent to explore:

```text
Run a dev server and explore the new API using curl.
Try edge cases like empty strings, very long inputs,
special characters, and missing required fields.
Report what you find.
```

## Integration with TDD

When manual testing finds issues:

```text
1. Manual test reveals: empty input crashes
2. Write test: test_parse_empty_input_returns_none()
3. Watch test fail (proves it catches the bug)
4. Fix code
5. Watch test pass
6. Re-run manual test to confirm
```

## Red Flags

- "Tests pass so it works" - tests might miss things
- "I manually verified" (with no evidence) - show the output
- Skipping edge cases - empty, null, large inputs matter
- Only testing happy path - test failure modes too
