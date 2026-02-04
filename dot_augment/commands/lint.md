---
name: lint
description: Run all linters including ast-grep coding standards on specified files or current changes
---

Run a comprehensive lint check on the specified files or all modified files.

## Steps

1. **Identify target files**:
   - If files are specified, lint those files
   - Otherwise, get list of modified files from `git status`
   - Filter to relevant file types (Python, etc.)

2. **Run ast-grep first** (coding standards):
   ```bash
   sg scan --config ~/.augment/ast-grep/sgconfig.yml <files>
   ```
   
   Report any violations by severity:
   - **Errors**: Must be fixed (nested functions, continue, ternary, mocks)
   - **Warnings**: Should be fixed (os.path, .format(), typing imports)

3. **Run ruff** (if Python project):
   ```bash
   ruff check <files>
   ruff format --check <files>
   ```

4. **Run mypy** (if configured):
   ```bash
   mypy <files>
   ```

5. **Summarize results**:
   ```
   ## Lint Results
   
   ### ast-grep (coding standards)
   - X errors, Y warnings
   - [list violations]
   
   ### ruff
   - X issues found
   - [list issues]
   
   ### mypy  
   - X type errors
   - [list errors]
   
   ### Overall Status
   ✅ All checks passed / ❌ X issues need attention
   ```

6. **Offer to fix**:
   - If issues found, ask if I should fix them
   - Fix ruff issues with `ruff check --fix` and `ruff format`
   - ast-grep issues require manual refactoring - explain each fix needed

