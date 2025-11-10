---
type: agent_requested
description: Python development patterns, package management with uv and poetry, testing with pytest, type safety, code organization, and modern Python best practices
---

# Python Development Guidelines

## Package Management

**Detection Strategy:**
1. Check for `uv.lock` first → use uv
2. Check for `poetry.lock` → use poetry
3. Inspect `pyproject.toml` for `[tool.uv]` or `[tool.poetry]` configuration

**Default Preference:** Use **uv** for new projects (faster, modern, better dependency resolution)

**Continuation Rule:** If `poetry.lock` exists, continue using poetry to maintain consistency

**CRITICAL: Always Use High-Level Commands**

✅ **Correct:**
```bash
uv add requests
uv add --dev pytest
poetry add requests
poetry add --group dev pytest
```

❌ **Incorrect:**
```bash
uv pip install requests  # Bypasses lock file
pip install requests     # Bypasses dependency management
```

**Rationale:** High-level commands update lock files, maintain dependency graphs, and ensure reproducible environments. Low-level commands bypass these safeguards and can cause dependency conflicts.

## Configuration with pyproject.toml

**Required Configuration (MUST be in pyproject.toml):**
- Project metadata (name, version, description, authors)
- Dependencies and dev dependencies
- Build system configuration
- Entry points and scripts

**Optional Tool Configuration (CAN be in separate files):**
- Tool configurations (ruff, mypy, pytest, black, coverage) can live in:
  - `pyproject.toml` (consolidated approach)
  - Separate files (`ruff.toml`, `mypy.ini`, `pytest.ini`) for better organization

**Rationale:** pyproject.toml is mandatory for project essentials (dependencies, metadata, build system) as it's the standard Python packaging format. Tool configurations can be separated if preferred for better organization, especially in large projects with extensive tool settings.

**Migration Guidance:** When encountering legacy files (setup.py, setup.cfg, requirements.txt), consolidate project metadata and dependencies into pyproject.toml. Tool configurations can remain separate if that improves clarity.

**Exception:** Only deviate from pyproject.toml for project essentials when there's a documented technical limitation or compatibility requirement

## Testing Standards

**Framework:** Use pytest for all Python testing

**Organization:** Tests should mirror source structure
- `src/module.py` → `tests/test_module.py`
- `src/package/submodule.py` → `tests/package/test_submodule.py`

**Fixtures:** Use pytest fixtures for:
- Shared test data
- Database connections
- Complex setup/teardown
- Dependency injection in tests

**Parametrization:** Use `@pytest.mark.parametrize` for multiple test cases:
```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```

**Anti-Mocking Philosophy:** See core-development-rules.md for comprehensive rationale on avoiding mocks

**Preferred Testing Approaches:**
- Use real implementations with test data
- Use in-memory databases (SQLite) instead of mocking database connections
- Create lightweight test doubles (fakes) instead of using mock frameworks
- Use dependency injection to swap real implementations for test implementations

**Coverage:** Aim for high coverage but focus on meaningful tests, not just coverage numbers

## Type Hints and Type Safety

**Requirement:** All function signatures must include type hints for parameters and return values

```python
def process_data(items: list[str], threshold: int = 10) -> dict[str, int]:
    """Process items and return counts."""
    return {item: len(item) for item in items if len(item) > threshold}
```

**Class Attributes:** Type hint all class attributes
```python
class DataProcessor:
    cache: dict[str, Any]
    max_size: int
    
    def __init__(self, max_size: int = 100) -> None:
        self.cache = {}
        self.max_size = max_size
```

**Modern Typing (Python 3.9+):**
- Use `list[str]` instead of `List[str]`
- Use `dict[str, int]` instead of `Dict[str, int]`
- Use `tuple[int, ...]` instead of `Tuple[int, ...]`

**Common Patterns:**
- `Optional[T]` or `T | None` for nullable values
- `Union[A, B]` or `A | B` for multiple types
- `TypedDict` for structured dictionaries
- `Protocol` for structural subtyping
- `Generic[T]` for generic classes

**Type Checking:** Use mypy as the standard type checker, configured in pyproject.toml

**Documentation Benefit:** Type hints serve as inline documentation, reducing the need for verbose parameter descriptions

## Code Organization

**Import Organization** (see core-development-rules.md):
1. Standard library imports
2. Third-party imports
3. Local application imports
4. Separate groups with blank lines

```python
import os
from pathlib import Path

import requests
from pydantic import BaseModel

from myapp.config import settings
from myapp.utils import helper
```

**Single Responsibility Principle:** Each module, class, and function should have one clear purpose

**Naming Conventions:**
- `snake_case` for functions and variables
- `PascalCase` for classes
- `UPPER_CASE` for constants
- Prefix private attributes with underscore: `_internal_method`

**Error Handling:**
- Use specific exception types, not generic `Exception`
- Provide context in error messages
- Use context managers for resource management
- Log errors with appropriate severity levels

## Modern Python Patterns

**String Formatting:** Use f-strings for all string interpolation
```python
# ✅ Correct
name = "Alice"
age = 30
message = f"{name} is {age} years old"

# ❌ Avoid
message = "%s is %d years old" % (name, age)
message = "{} is {} years old".format(name, age)
```

**Path Handling:** Use `pathlib.Path` instead of `os.path`
```python
from pathlib import Path

# ✅ Correct
config_path = Path("config") / "settings.json"
if config_path.exists():
    content = config_path.read_text()

# ❌ Avoid
import os
config_path = os.path.join("config", "settings.json")
if os.path.exists(config_path):
    with open(config_path) as f:
        content = f.read()
```

**Data Structures:** Strong preference for Pydantic models for structured data

**Strong Preference:** Use Pydantic models (provides validation, serialization, better type safety)
```python
from pydantic import BaseModel, EmailStr, Field

class User(BaseModel):
    name: str
    email: EmailStr
    age: int = Field(ge=0, le=150)

    class Config:
        frozen = True  # Make immutable if needed
```

**Dataclasses:** Only use when Pydantic is overkill (simple internal data structures with no validation needs)
```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Point:
    x: float
    y: float
```

**Context Managers:** Use `with` statements for file operations, database connections, locks
```python
# ✅ Correct
with open("data.txt") as f:
    data = f.read()

# ❌ Avoid
f = open("data.txt")
data = f.read()
f.close()
```

**Comprehensions:** Prefer list/dict/set comprehensions over loops when readable
```python
# ✅ Correct
squares = [x**2 for x in range(10)]
even_squares = {x: x**2 for x in range(10) if x % 2 == 0}

# ❌ Avoid (when comprehension is clearer)
squares = []
for x in range(10):
    squares.append(x**2)
```

**Ternary Expressions:** Avoid ternary expressions (conditional expressions) entirely

**Rationale:** Ternary expressions reduce readability and make code harder to debug. Explicit if/else statements are clearer and easier to step through in a debugger.

```python
# ❌ Avoid
result = value if condition else default
status = "active" if user.is_active else "inactive"

# ✅ Correct
if condition:
    result = value
else:
    result = default

if user.is_active:
    status = "active"
else:
    status = "inactive"
```

**Async/Await:**
- **Use async for:** I/O-bound operations (network requests, file I/O), concurrent tasks, web servers
- **Avoid async for:** CPU-bound work, simple scripts, when synchronous code is clearer
```python
import asyncio
import aiohttp

async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```

## Code Quality and Formatting

**Formatter:** Use `ruff format` for consistent code formatting
```bash
ruff format .
```

**Linter:** Use `ruff` (modern, fast) for linting
```bash
ruff check .
ruff check --fix .  # Auto-fix issues
```

**Configuration:** All tool configurations should be in pyproject.toml
```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.11"
strict = true
```

**Pre-commit Hooks:** Use pre-commit framework to run formatters and linters automatically
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## Documentation Standards

**Docstrings:** All public functions, classes, and modules must have docstrings

**Format:** Use Google-style or NumPy-style docstrings consistently

**Google-style Example:**
```python
def calculate_total(items: list[float], tax_rate: float = 0.1) -> float:
    """Calculate the total cost including tax.

    Args:
        items: List of item prices
        tax_rate: Tax rate as decimal (default: 0.1 for 10%)

    Returns:
        Total cost including tax

    Raises:
        ValueError: If tax_rate is negative

    Example:
        >>> calculate_total([10.0, 20.0], 0.1)
        33.0
    """
    if tax_rate < 0:
        raise ValueError("Tax rate cannot be negative")
    subtotal = sum(items)
    return subtotal * (1 + tax_rate)
```

**Type Hints as Documentation:** Type hints reduce the need for verbose parameter descriptions. Focus docstrings on explaining *why* and *how*, not *what* (which types already show).

## Virtual Environments

**Automatic Management:** uv and poetry manage virtual environments automatically
- uv creates `.venv` automatically on first `uv add` or `uv sync`
- poetry creates virtual environments in configured location

**Manual venv:** For projects without uv/poetry:
```bash
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows
```

**Never Install Globally:** Always use project-specific environments to avoid dependency conflicts

**Gitignore:** Always include `.venv` in `.gitignore`
```gitignore
.venv/
venv/
*.pyc
__pycache__/
```

## Key Principles

**Consistency:** Follow established patterns in the codebase. If the project uses a specific style or tool, continue using it.

**Explicitness:** Prefer explicit over implicit
- Use type hints everywhere
- Handle errors explicitly
- Make dependencies explicit in function signatures

**Maintainability:** Write code that's easy to understand and modify
- Clear naming
- Single responsibility
- Comprehensive tests
- Good documentation

**Modern Tooling:** Use current best practices and tools
- uv for fast dependency management
- ruff for linting and formatting
- pytest for testing
- mypy for type checking

**Reproducibility:** Ensure environments and dependencies are reproducible
- Lock files (uv.lock, poetry.lock)
- Pinned versions in pyproject.toml
- Documented setup instructions


