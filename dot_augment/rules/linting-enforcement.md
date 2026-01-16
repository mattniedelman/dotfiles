# Linting Enforcement

**Rule Type**: `always_apply` - This rule is applied to every interaction involving code changes

## Linting Stack

Matt's development environment uses a layered linting approach:

### 1. Global Ruff Configuration
- **Location**: `~/.config/ruff/ruff.toml`
- **Coverage**: `select = ['ALL']` with sensible ignores
- **What it enforces**:
  - Import organization (isort)
  - Unused imports/variables
  - f-strings over .format() and % formatting
  - pathlib over os.path
  - No blanket `# noqa` or `# type: ignore`
  - Type hint style (modern generics)
  - Docstring conventions
  - All pycodestyle, pyflakes, pyupgrade, and more

### 2. ast-grep Structural Rules
- **Location**: `~/.config/ast-grep/sgconfig.yml` (with rules in `~/.config/ast-grep/rules/`)
- **What it enforces** (not covered by ruff):
  - No nested functions or classes
  - No `continue` statements
  - No ternary expressions
  - No `assert x == True/False`
  - No unittest.mock or pytest-mock imports

### 3. mypy Type Checking
- Use `mypy --strict` for comprehensive type checking

## Mandatory Linting Workflow

### After Making Python Code Changes

Run in this order:

```bash
# 1. ast-grep (structural rules) - errors are blocking
sg scan <file>

# 2. ruff (style, imports, modern Python)
ruff check <file>

# 3. mypy (type checking)
mypy <file>
```

### Priority of Fixes
1. **ast-grep errors**: MUST fix before proceeding (nested functions, continue, ternary, mocks)
2. **ruff errors**: MUST fix (most can be auto-fixed with `ruff check --fix`)
3. **mypy errors**: MUST fix for type safety
4. **ast-grep warnings**: SHOULD fix (os.path usage can proceed with justification)

### 3. Address All Diagnostics
- **Rule**: Fix all linting diagnostics by addressing the underlying issues
- **Rationale**: Linting errors indicate potential bugs, style inconsistencies, or maintainability issues. Suppressing them without fixing the root cause degrades code quality over time
- **Implementation**:
  - **Always attempt to fix linting errors** by making appropriate code changes
  - **Never ignore or suppress linting errors** unless explicitly instructed by the user
  - **Balance fixes with system stability** - don't introduce breaking changes or new bugs while fixing linting issues
  - **Prioritize proper fixes over suppressions** - refactor code, split long lines, add type hints, or restructure logic as needed

### 4. Structured Approval Process for Suppressions
- **Rule**: Follow a structured approval process before suppressing any linting diagnostic
- **Process**:
  1. **Explain the situation**: Describe to the user why the linting error exists and why it's difficult to address
  2. **Analyze consequences**: Explain the potential consequences of fixing it versus leaving it
  3. **Request explicit approval**: Ask the user for permission before adding any suppression
  4. **Document the suppression**: If approved, add an inline suppression comment that:
     - Uses the linter-specific syntax (e.g., `# noqa: E501` for flake8, `# type: ignore[error-code]` for mypy, `# ruff: noqa: RULE` for ruff)
     - Includes a brief explanation of why the suppression is necessary
     - References the specific linting rule being suppressed (not a blanket ignore)

### 5. Verify Fixes
- **Rule**: Run linters again after making fixes to verify all issues are resolved
- **Implementation**:
  - Re-run all linters on the modified files
  - Confirm that no new diagnostics were introduced
  - Ensure all original diagnostics have been resolved

### 6. Report Results to User
- **Rule**: Always report linting results to the user before considering the task complete
- **Implementation**:
  - Report which linters were run and on which files
  - List any diagnostics found and how they were addressed
  - Confirm that all diagnostics have been resolved
  - If suppressions were added (with user approval), list them with justification

## Appropriate Suppression Scenarios

Only suppress linting errors in specific, justified cases with explicit user approval:

### Examples of Appropriate Scenarios (with user approval)
- **Line length violations**: URLs or long string literals that cannot be reasonably split without breaking functionality
- **Type checking issues**: Third-party libraries that lack proper type stubs or have incorrect type definitions
- **False positives**: Intentional use of patterns that trigger false positives in specific, well-understood contexts
- **Generated code**: Auto-generated code where manual fixes would be overwritten
- **Performance-critical code**: Cases where the "correct" pattern has measurable performance implications

### Examples of Inappropriate Suppressions (should always be fixed)
- Line length violations in regular code (refactor into multiple lines or extract to variables)
- Missing type hints (add proper type annotations)
- Unused imports or variables (remove them)
- Style violations (fix the style to match project standards)
- Complexity warnings (refactor to reduce complexity)

## Suppression Best Practices

When suppressions are necessary and approved, follow these guidelines:

- **Never use blanket suppressions**: Avoid `# noqa` without specifying the rule code, or `# type: ignore` without the specific error
- **Be specific**: Always reference the exact linting rule being suppressed (e.g., `# noqa: E501` not just `# noqa`)
- **Add context**: Include a brief comment explaining why the suppression is necessary
- **Minimize scope**: Use inline suppressions for specific lines rather than file-level or block-level ignores
- **Review regularly**: Suppressions should be revisited during refactoring to see if they can be removed

## Examples

### Good Suppression (with user approval)
```python
# This URL cannot be split without breaking the API endpoint
VERY_LONG_API_URL = "https://api.example.com/v1/very/long/endpoint/path/that/cannot/be/shortened"  # noqa: E501

# Third-party library missing type stubs, tracked in issue #123
result = external_library.process(data)  # type: ignore[no-untyped-call]
```

### Bad Suppression (should be fixed instead)
```python
# ❌ Blanket suppression without explanation
result = some_function()  # noqa

# ❌ Generic type ignore
result = some_function()  # type: ignore

# ❌ Should be fixed instead of suppressed
very_long_line = first_value + second_value + third_value + fourth_value + fifth_value  # noqa: E501
```

## Extensive Fix Scenarios

### When Linting Requires Many Fixes

**Auto-fix limits:**
- **1-20 simple issues**: Auto-fix without asking (safe changes like unused imports, whitespace)
- **21-50 issues**: Inform user and ask permission before fixing
- **51+ issues**: Present options to user

**When linting finds 51+ issues:**

```
EXTENSIVE LINTING FIXES REQUIRED

Linter found [number] issues across [number] files.

Issue breakdown:
- [number] errors (must fix)
- [number] warnings (should fix)
- [number] style issues (optional)

Estimated changes: ~[number] lines

Options:
1. Fix all issues now (may take time and affect many files)
2. Fix critical issues only (errors, not warnings)
3. Fix file-by-file with your approval for each
4. Show me the issues and let me decide which to fix
5. Skip linting fixes for now

Your choice:
```

### Invasive Fix Scenarios

**When fixes would significantly change code structure:**

```
⚠️  INVASIVE LINTING FIXES DETECTED

Some linting fixes would require significant code changes:
- [description of invasive changes]

Examples:
- Refactoring complex functions to reduce complexity
- Restructuring code to fix type errors
- Breaking up long functions

These changes go beyond simple formatting.

Options:
1. Proceed with all fixes (including invasive ones)
2. Skip invasive fixes, only apply simple fixes
3. Review invasive fixes one-by-one for approval
4. Skip all linting fixes

Your choice:
```

### File-by-File Approval Workflow

**When user chooses file-by-file approval:**

For each file with issues:
```
File: [filename]
Issues: [number]
- [list of issues]

Fix these issues? (yes/no/skip remaining)
```

---

## Integration with Development Workflow

This linting enforcement rule integrates with the existing development workflow:

1. **After making code edits**: Run linters automatically
2. **Before committing code**: Ensure all linting diagnostics are resolved
3. **During code review**: Verify that no suppressions were added without justification
4. **As part of CI/CD**: Linting checks should pass in automated pipelines

## Relationship to Existing Rules

This rule complements and enforces the linting guidelines in `core-development-rules.md`:
- Builds on the "Linting Error Resolution" section
- Enforces the "When Linting Errors Cannot Be Fixed" process
- Implements the "Appropriate Suppression Scenarios" guidelines
- Ensures the "Suppression Best Practices" are followed consistently

