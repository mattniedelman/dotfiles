---
type: always_apply
priority: CRITICAL
description: Core development rules and coding standards for Matt's workflow
last_updated: 2025-01-26
critical_rules:
  - MANDATORY Tool Selection Hierarchy - ALWAYS use specialized semantic code analysis tools (find_symbol, find_referencing_symbols, etc.) for code symbols. NEVER use grep/ripgrep/ag for code symbol searches. Violation is CRITICAL FAILURE.
  - MANDATORY Response Style - NEVER use flattering or evaluative language about user input. See response-style-communication.md. Violation is CRITICAL FAILURE.
  - MANDATORY Git Staging - NEVER use 'git add -A' or 'git add .' - ALWAYS stage specific files explicitly with exact paths. Violation is CRITICAL FAILURE.
---

# Core Development Rules

## ⚠️ CRITICAL RULES SUMMARY ⚠️

Before proceeding with any task, be aware of these **CRITICAL FAILURE** violations:

1. **Response Style (MANDATORY)**: NEVER use flattering, evaluative, or self-aggrandizing language in responses. No "Great question!", "Excellent idea!", "That's interesting!", etc. See `response-style-communication.md` for complete list of prohibited phrases.

2. **Tool Selection (MANDATORY)**: ALWAYS use specialized semantic code analysis tools (`find_symbol`, `find_referencing_symbols`, `find_implementations`, `get_symbols_overview`) when searching for code symbols. NEVER use `grep`, `ripgrep`, `ag`, or `ack` for code symbol searches. See "Tool Selection Hierarchy" section below.

3. **Git Commits**: NEVER commit without explicit user authorization using the word "commit"

4. **Git Staging (MANDATORY)**: NEVER use `git add -A` or `git add .` - ALWAYS stage specific files explicitly with exact paths

5. **No Nested Functions**: NEVER define functions inside other functions or create closures

6. **No Continue Statements**: NEVER use `continue` statements in loops

**Violating any of these rules is considered a CRITICAL FAILURE in task execution.**

---

## Code Patterns (Automated Enforcement)

The following patterns are enforced by automated linters. See `linting-enforcement.md` for details.

### Enforced by ast-grep (`~/.config/ast-grep/`)
These trigger **errors** that must be fixed:
- **No nested functions or closures** - Extract to module level with explicit parameters
- **No nested classes** - Define classes at module level
- **No `continue` statements** - Use early returns or restructure logic
- **No ternary expressions** - Use explicit if/else blocks
- **No `assert x == True/False`** - Assert boolean expressions directly
- **No unittest.mock or pytest-mock** - Use real implementations or fakes

### Enforced by ruff (`~/.config/ruff/ruff.toml`)
- **Import organization** - Handled by isort rules (I001, I002)
- **String formatting** - Use f-strings (UP031, UP032)
- **Path handling** - Use pathlib (PTH rules)
- **Modern type hints** - Use `list[str]` not `List[str]` (UP rules)
- **No blanket suppressions** - Specific rule codes required (PGH rules)

### Why These Patterns Matter
- Nested functions cannot be tested in isolation
- Continue statements create hidden control flow
- Ternary expressions reduce readability for complex conditions
- Mocks test configuration, not behavior

## Tool Selection Hierarchy

### ⚠️ MANDATORY: Semantic Tools for Code Symbols ⚠️

**CRITICAL FAILURE** to use generic text search (`grep`, `ripgrep`, `ag`, `ack`) for code symbols when semantic tools are available.

| Search Target | Required Tool | Fallback (justify use) |
|--------------|---------------|------------------------|
| Symbol definitions | `find_symbol` | Never for code symbols |
| Symbol usages | `find_referencing_symbols` | Never for code symbols |
| Implementations | `find_implementations` | Never for code symbols |
| File structure | `get_symbols_overview` | Never for code symbols |
| Comments, TODOs | `view` with `search_query_regex` | `grep`/`ripgrep` |
| Config files (YAML, JSON) | `grep`/`ripgrep` | - |
| String literals, logs | `grep`/`ripgrep` | - |

### Decision Rule

**Before ANY search**: Is the target a code symbol (class, function, variable, method)?
- **YES** → MUST use semantic tools. No exceptions.
- **NO** → May use text search.

### Prohibited Patterns
- ❌ `grep -r "class ClassName"` or `ripgrep "def function_name"`
- ❌ Text search for "all usages of" any code symbol
- ❌ Justifying text search with "it's faster" or "it's simpler"

## Structured Thinking for Complex Tasks

### When to Use Think-Strategies

**Rule**: Use the `think-strategies` MCP tools when task complexity exceeds what can be reliably handled through direct action. The overhead of structured thinking is justified when the cost of mistakes or missed considerations is high.

**Complexity indicators that warrant structured thinking**:

1. **Multiple competing hypotheses**:
   - Debugging where the root cause is unclear
   - Performance issues with several possible sources
   - Flaky tests with intermittent failures
   - Security vulnerabilities with multiple potential vectors

2. **Significant architectural decisions**:
   - Designing new systems or major components
   - Choosing between fundamentally different approaches
   - Decisions with long-term implications that are costly to reverse
   - Tradeoffs involving multiple stakeholders or concerns

3. **Complex refactoring or migrations**:
   - Changes touching many files or systems
   - Refactoring with unclear scope or dependencies
   - Database migrations with data transformation
   - API changes affecting multiple consumers

4. **Investigation and analysis**:
   - Understanding unfamiliar codebases
   - Reverse-engineering undocumented systems
   - Root cause analysis for production incidents
   - Security audits or vulnerability assessments

5. **Multi-step planning**:
   - Tasks requiring coordination across multiple systems
   - Work that must be done in a specific order
   - Changes with rollback considerations
   - Migrations requiring careful sequencing

### Strategy Selection Guide

Choose the appropriate thinking strategy based on the problem type:

| Problem Type | Recommended Strategy | When to Use |
|-------------|---------------------|-------------|
| Step-by-step problem solving | `chain_of_thought` | Linear problems with clear progression |
| Debugging with hypotheses | `react` | Need to form hypothesis → test → observe → refine |
| Exploring alternatives | `tree_of_thoughts` | Multiple valid approaches to evaluate |
| Breaking down complex tasks | `rewoo` | Planning before execution, separating reasoning from action |
| Self-correction needed | `self_consistency` | High-stakes decisions needing verification |
| Stepping back for context | `step_back` | When stuck in details, need broader perspective |
| Navigating tradeoffs | `trilemma` | Decisions with competing constraints |

### When NOT to Use Structured Thinking

**Skip think-strategies for**:
- Simple, well-defined tasks with clear implementation paths
- Routine code changes (adding a field, fixing a typo, updating a dependency)
- Tasks where the approach is obvious and low-risk
- Quick lookups or information retrieval
- Following explicit user instructions with no ambiguity

**Rule of thumb**: If you can confidently execute the task in 2-3 steps without needing to track state or consider alternatives, proceed directly. If you find yourself uncertain, backtracking, or juggling multiple considerations, invoke structured thinking.

### Using Think-Strategies Effectively

**Session management**:
- Use `think-session-manager` to resume prior thinking sessions on ongoing problems
- Search for related sessions before starting new investigations
- Persist sessions for complex problems that may span multiple conversations

**Integration with other tools**:
- Use `plannedActions` to queue tool calls that will inform the next thought
- Use `actionResults` to incorporate tool outputs into reasoning
- Combine with basic-memory to document conclusions and decisions

**Quality reflection**:
- Use the `qualityRating` field to self-assess reasoning quality
- Adjust approach if ratings indicate poor fit between strategy and problem

### Examples

```
❌ Task: "Add a created_at field to the User model"
   → Direct action. Simple, well-defined, low-risk.

✅ Task: "Figure out why the payment processing is sometimes failing"
   → Use react strategy. Multiple hypotheses, need to investigate and refine.

❌ Task: "Update the README with the new API endpoint"
   → Direct action. Straightforward documentation update.

✅ Task: "Design the caching layer for the API"
   → Use tree_of_thoughts. Multiple valid approaches (Redis, in-memory, CDN),
     need to evaluate tradeoffs.

❌ Task: "Run the tests and fix any failures"
   → Direct action initially. Escalate to structured thinking if failures
     are complex or interconnected.

✅ Task: "Migrate from REST to GraphQL without breaking existing clients"
   → Use rewoo strategy. Complex multi-step migration requiring careful
     planning before execution.
```

## Deep Modules and Simple Interfaces

### Interface Design
- **Rule**: Create deep modules with simple, powerful interfaces that hide complex implementation details
- **Rationale**: Based on "A Philosophy of Software Design" - minimize cognitive load while maximizing functionality
- **Implementation**: 
  - Few public methods with clear, intuitive names
  - Hide implementation complexity behind clean abstractions
  - Provide sensible defaults to reduce parameter burden

### API Consolidation
- **Rule**: Consolidate related functionality into cohesive modules rather than fragmenting across multiple small modules
- **Rationale**: Reduces the number of interfaces developers need to learn and maintain
- **Example**: Prefer one client class with multiple methods over multiple specialized client classes

## Complexity Management

### Avoid Shallow Modules
- **Rule**: Don't create modules that provide little functionality relative to their interface complexity
- **Rationale**: Shallow modules increase overall system complexity without proportional benefit
- **Test**: If a module's interface is nearly as complex as its implementation, consider refactoring

### Strategic vs Tactical Programming
- **Rule**: Always consider long-term design implications, not just immediate implementation needs
- **Implementation**: 
  - Design APIs that can evolve without breaking changes
  - Choose general-purpose solutions over highly specialized ones
  - Invest time in proper abstractions upfront

### Remove Unnecessary Complexity
- **Rule**: Actively eliminate complexity that doesn't provide proportional value
- **Examples**:
  - Remove redundant processing passes
  - Consolidate similar logic patterns
  - Eliminate configuration options that serve edge cases
  - Use built-in solutions over custom implementations when possible

## Python-Specific Best Practices

### Type Hints and Documentation
- **Rule**: Use type hints for all public functions and class methods (enforced by mypy)
- **Documentation**: Include docstrings for all public APIs explaining purpose, parameters, and return values

### Error Handling
- Prefer specific exception types over generic Exception
- Include meaningful error messages with context
- Use logging consistently (avoid mixing print, console.print, etc.)

### Comment Placement
- Write comments on their own line(s) above the code they describe
- Avoid inline comments that cause line length issues

## Package Management

**Primary Reference**: See `python-development.md` for detailed Python package management.

### Quick Reference

| Lock File Present | Use Package Manager |
|-------------------|---------------------|
| `poetry.lock` | Poetry |
| `uv.lock` or none | uv (default) |

**CRITICAL**: Never bypass lock files with low-level commands (`pip install`, `uv pip install`).

**Non-Python Languages**: Use appropriate package managers (npm/yarn/pnpm for JS, cargo for Rust, go mod for Go). Never manually edit package files when commands are available. See `authorization-policies.md` for installation authorization requirements.

## Testing and Quality

### Comprehensive Testing
- **Rule**: Write tests for all new functionality and maintain high test coverage
- **Implementation**:
  - Unit tests for individual functions and methods
  - Integration tests for API endpoints and workflows
  - Use pytest fixtures for test data and setup
  - Test edge cases and error conditions

### Test Organization
- **Rule**: Organize tests to mirror the structure of the code being tested
- **Implementation**:
  - Clear test names that describe what is being tested
  - Group related tests using pytest marks
  - Separate unit tests from integration tests
  - Use meaningful assertions with descriptive failure messages


### Test Documentation
- **Rule**: Test docstrings should provide meaningful context, not restate what is obvious from the test name or code
- **Rationale**: Redundant docstrings add noise without value. Documentation should explain WHY a test exists, not WHAT it literally does
- **Implementation**:
  - Remove docstrings that merely restate the test function name (e.g., "Test that X returns Y" when the test is named `test_x_returns_y`)
  - Keep docstrings that explain:
    - Non-obvious business logic or API contracts being verified
    - Edge cases or boundary conditions being tested
    - Why the test exists (what behavior it protects against)
    - Complex test setup or data relationships
  - Keep AAA (Arrange/Act/Assert) section comments as they provide structure
  - Remove inline comments that simply restate what the code does
  - Add inline comments only when they explain non-obvious choices, complex logic, or workarounds
- **Examples**:
  ```python
  # ❌ Redundant - test name already says this
  def test_threshold_filters_members(self):
      """Test that threshold filters members."""
      
  # ✅ Good - explains non-obvious behavior
  def test_threshold_filters_members(self):
      """Verify that clusters remain in response even when all members are filtered out."""
      
  # ✅ Good - no docstring needed when test name is clear
  def test_invalid_uuid_returns_422(self):
      # Arrange
      response = client.get("/endpoint/invalid-uuid")
      
      # Assert
      assert response.status_code == 422
  ```

### Inline Comments for Expected Test Outcomes
- **Rule**: Include inline comments that explain expected test outcomes when they help readers understand assertions without mental calculation
- **Rationale**: Comments explaining which specific test data items should pass/fail filtering or other operations provide valuable context that makes tests easier to understand and maintain
- **When to Add**:
  - When assertions check counts or filtering results that depend on specific test data values
  - When the expected outcome requires understanding which items from test fixtures meet certain criteria
  - When boundary conditions or edge cases are being tested with specific values
  - When the relationship between test data and expected results is not immediately obvious
- **When to Skip**:
  - When the test name and assertion are completely self-explanatory
  - When the expected value is trivial (e.g., checking for empty list, single item, etc.)
  - When the comment would just restate the assertion without adding context
- **Examples**:
  ```python
  # ✅ Good - explains which items pass the filter
  def test_threshold_filters_members(self):
      # Act
      response = client.get("/clusters?threshold=0.5")
      
      # Assert
      # Expected: ws1(0.9), ws2(0.7), ws5(0.8), ws6(0.5 - excluded), ws8(0.6)
      total_members = sum(len(cluster["members"]) for cluster in data["clusters"])
      expected_filtered_members = 4
      assert total_members == expected_filtered_members
  
  # ✅ Good - explains boundary behavior
  def test_threshold_exactly_at_boundary(self):
      # Act
      response = client.get("/clusters?threshold=0.7")
      
      # Assert
      # ws2 with score 0.7 should be excluded (threshold is >)
      all_members = [m for cluster in data["clusters"] for m in cluster["members"]]
      member_ids = {m["workstation_id"] for m in all_members}
      assert "ws2" not in member_ids
      assert "ws1" in member_ids
  
  # ❌ Redundant - doesn't add value beyond the assertion
  def test_returns_three_clusters(self):
      # Act
      response = client.get("/clusters")
      
      # Assert
      # Should have 3 clusters
      assert len(data["clusters"]) == 3
  
  # ✅ Good - no comment needed, assertion is self-explanatory
  def test_returns_three_clusters(self):
      # Act
      response = client.get("/clusters")
      
      # Assert
      expected_cluster_count = 3
      assert len(data["clusters"]) == expected_cluster_count
  ```
- **Best Practices**:
  - Place the comment immediately before the assertion or expected value declaration it explains
  - Be specific about which test data items are included/excluded and why
  - Include relevant values from test data (e.g., scores, IDs) to make the comment self-contained
  - Use concise language that focuses on the outcome, not restating the code
### Test Structure Pattern
- **Rule**: All tests must follow the "Arrange, Act, Assert" (AAA) pattern for clarity and consistency
- **Rationale**: The AAA pattern makes tests easier to read, understand, and maintain by clearly separating test setup, execution, and verification
- **Implementation**:
  - **Arrange**: Set up test data, mock dependencies, and configure the system under test. Define expected values as variables here as well.
  - **Act**: Execute the specific behavior or function being tested
  - **Assert**: Verify that the expected outcome occurred
  - Use blank lines to visually separate the three sections
  - Keep each section focused on its single responsibility
  - Avoid mixing arrangement and assertion logic
- **Example**:
  ```python
  def test_user_authentication():
      # Arrange
      user = User(username="test_user", password="hashed_password")
      auth_service = AuthenticationService()

      # Act
      result = auth_service.authenticate(user.username, "correct_password")

      # Assert
      assert result.is_authenticated is True
      assert result.user_id == user.id
  ```
- **Exceptions**: Simple one-line tests or property-based tests may deviate from this pattern when the separation would reduce clarity

### Assert Boolean Expressions Directly
- **Rule**: Enforced by ast-grep (`no-assert-equals-true`, `no-assert-equals-false`)
- **Summary**: Use `assert condition` not `assert condition == True`; use `assert not condition` not `assert condition == False`

### Fuzzing and Property-Based Testing
- **Rule**: Use automated test data generation to discover edge cases and improve test coverage
- **Rationale**: Fuzzing helps discover boundary conditions and edge cases that manual test creation often misses, leading to more robust and reliable code
- **Implementation**:
  - **Polyfactory for Pydantic Models**: Generate test objects automatically based on Pydantic schemas, leveraging existing type hints and validation rules
  - **Hypothesis for Property-Based Testing**: Generate diverse test inputs to verify function properties and invariants across wide input ranges
  - **Faker for Realistic Data**: Generate human-readable, realistic sample data (names, addresses, emails) for integration tests
- **Usage Guidelines**:
  - Use Polyfactory for testing Pydantic model validation, serialization, and deserialization
  - Use Hypothesis for testing mathematical properties, data transformations, and API contracts
  - Use Faker for integration tests requiring realistic-looking data that humans might review
  - Generated test data should complement, not replace, carefully crafted test cases for known edge cases and critical business logic scenarios
- **Example Applications**:
  - Test API endpoints with automatically generated request payloads
  - Verify data processing functions handle unexpected input combinations
  - Generate realistic user data for end-to-end testing scenarios

### Avoid Mocks in Tests
- **Rule**: Strongly discourage the use of mocks, stubs, and test doubles in unit and integration tests
- **Rationale**: Overuse of mocks leads to brittle tests that verify test setup rather than actual behavior. Mocked tests can pass even when real code is broken, providing false confidence. Tests with extensive mocking often test the mock configuration more than the actual system behavior
- **Preferred Alternatives**:
  - **Dependency Injection**: Design code to accept dependencies as parameters, allowing real implementations to be swapped for test implementations
  - **In-Memory Implementations**: Use in-memory databases (SQLite, DuckDB), in-memory message queues, or in-memory caches instead of mocking
  - **Lightweight Test Implementations**: Create simple, real implementations of interfaces specifically for testing (fakes, not mocks)
  - **Architectural Refactoring**: Extract pure functions that don't require mocking, use functional core/imperative shell pattern to isolate side effects
  - **Real Instances with Test Data**: Use actual object instances populated with test data rather than mocked objects
  - **Test Fixtures**: Create reusable test data and object factories that produce real instances
- **When Mocks Are Acceptable**:
  - Explicitly requested by the user with clear justification for why alternatives won't work
  - Testing interactions with truly external systems that cannot be replicated (third-party payment APIs, email services, SMS gateways)
  - The cost of using real implementations is prohibitively high (e.g., expensive cloud services, long-running operations)
  - Even in these cases, prefer creating real test doubles (fake implementations) over using mock frameworks
- **Code Smell Indicator**: If code is difficult to test without extensive mocking, this indicates the architecture should be reconsidered. Well-designed code with proper separation of concerns should be testable with minimal or no mocking
- **Implementation Guidelines**:
  - Design interfaces and abstractions that are easy to implement for testing
  - Separate I/O and side effects from business logic
  - Use constructor injection or function parameters for dependencies
  - Create test-specific implementations that behave like real components but are simpler and faster
  - When mocks are truly necessary, keep them simple and verify behavior, not implementation details

### Linting
- **Rule**: See `linting-enforcement.md` for complete linting workflow
- **Key points**:
  - Fix linting errors rather than suppressing them
  - Never use blanket `# noqa` or `# type: ignore` - always specify the rule
  - Request user approval before adding any suppression

## Code Organization

### Single Responsibility Principle
- **Rule**: Each module, class, and function should have a single, well-defined responsibility
- **Implementation**:
  - Functions should do one thing well
  - Classes should represent cohesive concepts
  - Modules should group related functionality

### Consistent Naming Conventions
- **Rule**: Use consistent, descriptive naming throughout the codebase
- **Implementation**:
  - Use snake_case for variables and functions
  - Use PascalCase for classes
  - Use UPPER_CASE for constants
  - Choose names that clearly indicate purpose and scope

### Configuration Management
- **Rule**: Centralize configuration and avoid magic numbers scattered throughout code
- **Implementation**:
  - Use configuration files or environment variables
  - Define constants at module level for magic numbers
  - Provide sensible defaults for optional configuration
  - Document configuration options clearly

## Version Control Practices

### ⚠️ CRITICAL: Git Commit Authorization Policy ⚠️

**ABSOLUTE RULE**: The AI assistant must NEVER execute `git commit`, `git push`, or any git operation that modifies repository history without EXPLICIT user authorization.

**"Explicit authorization" means:**
- User must use the word "commit", "push", "merge", "rebase", or equivalent git operation term
- Phrases like "save", "finish", "complete", "done" do NOT constitute authorization
- When in doubt, DO NOT commit - instead ask the user

**Before ANY commit:**
1. Confirm you have explicit authorization
2. Present the proposed commit message to the user
3. Wait for user approval
4. Only then execute the commit

**Violation of this policy is a critical failure.**

---

### Git Commits
- **Rule**: Only perform git commits when explicitly requested by the user
- **Rationale**: Committing code is a deliberate action that should be under the user's control and timing
- **Implementation**:
  - **NEVER** automatically commit changes after making edits
  - **NEVER** commit as part of a workflow, even if it seems like a natural completion step
  - **NEVER** proactively suggest or ask to commit unless the user has explicitly mentioned committing
  - **ONLY** commit when the user explicitly uses commit-related commands (see examples below)
  - When explicitly asked to commit, ALWAYS confirm the commit message with the user before executing

### What Constitutes an Explicit Commit Request

**Valid commit requests (these authorize commits):**
- "Commit these changes"
- "Make a commit with message X"
- "Git commit this"
- "Commit the changes with message: feat(api): add new endpoint"
- "Stage and commit these files"

**Invalid/ambiguous phrases (these do NOT authorize commits):**
- "Save this" / "Save my work" / "Save these changes"
- "Finish this feature" / "Complete this task"
- "We're done here" / "That's good"
- "Push this to the repo" (requires separate explicit commit request first)
- "Create a PR" (requires separate explicit commit request first)
- "Make this permanent"
- Any phrase that doesn't explicitly use the word "commit" or "git commit"

**When in doubt**: If the user's request doesn't explicitly mention "commit" or "committing," do NOT commit. Instead, inform the user that changes have been made and are ready to commit when they choose to do so.

### Git Operations Requiring Explicit Permission

The following git operations **REQUIRE explicit user permission** and must NEVER be performed automatically:

**Prohibited without explicit permission:**
- `git commit` - Creating commits
- `git push` - Pushing to remote repositories
- `git merge` - Merging branches
- `git rebase` - Rebasing commits (including interactive rebase)
- `git cherry-pick` - Cherry-picking commits
- `git reset --hard` - Hard resets that discard changes
- `git clean` - Removing untracked files
- `git branch -D` - Force deleting branches
- `git tag` - Creating tags
- `git commit --amend` - Amending commits
- `git revert` - Reverting commits

**Allowed without explicit permission (read-only or safe operations):**
- `git status` - Checking repository status
- `git diff` - Viewing differences
- `git log` - Viewing commit history
- `git branch` (list only) - Listing branches
- `git show` - Showing commit details
- `git fetch` - Fetching from remote (doesn't modify working tree)

**Requires explicit permission but can be suggested:**
- `git add` - Staging files (can suggest: "These files are ready to stage. Would you like me to run git add?")
- `git checkout` / `git switch` - Switching branches (can suggest if user asks to work on different branch)
- `git stash` - Stashing changes (can suggest if needed for branch switching)

**Critical rule**: When user requests an operation that requires a prerequisite git operation (e.g., "push this" requires committing first), AI must:
1. Inform user of the prerequisite
2. Request explicit permission for each operation separately
3. Never assume permission for prerequisites

### Workflow Completion and Commits

**Critical Rule**: Workflow completion phrases do NOT authorize commits.

**Phrases that complete work but do NOT authorize commits:**
- "Finish this feature"
- "Complete this task"
- "We're done with this"
- "That's everything"
- "Implement feature X" (even if implementation is complete)
- "Fix bug Y" (even if fix is complete)
- "Wrap this up"
- "Finalize the changes"

**Correct AI behavior when work is complete:**
1. Complete all requested code changes
2. Run tests if requested
3. Inform user: "I've completed [description of work]. The changes are ready to commit when you're ready. Would you like me to commit these changes?"
4. Wait for explicit commit authorization

**Exception**: If user's original request explicitly included committing (e.g., "Implement feature X and commit it"), then commit authorization is included. However, AI should still confirm the commit message before executing.

**When user says "finish" or "complete":**
- Interpret as: finish the code changes only
- Do NOT interpret as: finish everything including committing
- After completing code changes, remind user that changes are uncommitted

### Objective Language in Code and Documentation

**Rule**: Use objective, factual language in all code-related content. See `response-style-communication.md` for comprehensive guidelines.

**Quick reference:**
- ❌ "Greatly improve error handling" → ✅ "Refactor error handling to use custom exception types"
- ❌ "Add amazing new feature" → ✅ "Add user authentication feature"
- ❌ "Perfect the API design" → ✅ "Simplify API by consolidating endpoints"

### GitHub API Tool for GitHub Resources

**Rule**: Always use the `github-api` tool for accessing and manipulating remote GitHub resources. Never use `web-fetch` for remote GitHub resources.

**Rationale**: The `github-api` tool is specifically designed for GitHub operations, provides proper authentication, structured data responses, and handles rate limiting appropriately. Using `web-fetch` for remote GitHub resources bypasses authentication, provides unstructured HTML instead of API data, and can lead to rate limiting issues.

**Scope**: This rule applies **only to remote GitHub resources** (repositories, issues, PRs, etc. hosted on github.com). It does **not** apply to local workspace files or directories that happen to be part of a GitHub repository.

**Implementation**:
- **ALWAYS** use the `github-api` tool for remote GitHub operations as the first choice
- **NEVER** use `web-fetch` to access remote GitHub URLs (github.com, raw.githubusercontent.com, etc.)
- **Use `gh` CLI as fallback** only when the `github-api` tool genuinely cannot accomplish the task
- **ALWAYS** use appropriate API endpoints and query parameters for efficient data retrieval

**Common GitHub API Operations**:
- **Repository operations**:
  - `GET /repos/{owner}/{repo}` - Get repository details
  - `GET /repos/{owner}/{repo}/contents/{path}` - Get file contents
  - `POST /repos/{owner}/{repo}/forks` - Fork a repository

- **Pull request operations**:
  - `GET /repos/{owner}/{repo}/pulls` - List pull requests (use `state`, `head`, `base` parameters)
  - `GET /repos/{owner}/{repo}/pulls/{number}` - Get PR details
  - `POST /repos/{owner}/{repo}/pulls` - Create a pull request
  - `GET /repos/{owner}/{repo}/pulls/{number}/files` - Get PR file changes
  - `PATCH /repos/{owner}/{repo}/pulls/{number}` - Update a pull request
  - `PUT /repos/{owner}/{repo}/pulls/{number}/merge` - Merge a pull request

- **Issue operations**:
  - `GET /repos/{owner}/{repo}/issues` - List issues (use `filter`, `state`, `labels` parameters)
  - `GET /issues` - List user's issues across all repos (use `filter` parameter)
  - `GET /repos/{owner}/{repo}/issues/{number}` - Get issue details
  - `POST /repos/{owner}/{repo}/issues` - Create an issue
  - `PATCH /repos/{owner}/{repo}/issues/{number}` - Update an issue
  - `POST /repos/{owner}/{repo}/issues/{number}/comments` - Comment on an issue

- **Search operations**:
  - `GET /search/issues` - Search issues and PRs (use `q` parameter with `is:pr`, `is:issue`, `author:@me`, etc.)
  - `GET /search/code` - Search code
  - `GET /search/commits` - Search commits (use `author:{username}` or `committer:{username}`)

- **Workflow and CI operations**:
  - `GET /repos/{owner}/{repo}/actions/runs` - List workflow runs
  - `GET /repos/{owner}/{repo}/actions/runs/{run_id}` - Get run details
  - `GET /repos/{owner}/{repo}/commits/{sha}/check-runs` - Get check runs for a commit
  - `GET /repos/{owner}/{repo}/commits/{sha}/status` - Get commit status (covers more CIs)

- **Release operations**:
  - `GET /repos/{owner}/{repo}/releases` - List releases
  - `GET /repos/{owner}/{repo}/releases/{id}` - Get release details
  - `POST /repos/{owner}/{repo}/releases` - Create a release

**When to use `gh` CLI as fallback**:
- Only when the `github-api` tool genuinely cannot accomplish the required task
- When you need interactive operations that are better suited for CLI (e.g., interactive PR creation)
- When explicitly requested by the user to use the CLI
- **MUST** document why `github-api` cannot be used before falling back to `gh` CLI

**Prohibited Patterns (NEVER DO THIS)**:
- **❌ NEVER** use `web-fetch` with remote GitHub URLs:
  - `web-fetch("https://github.com/{owner}/{repo}/pull/{number}")`
  - `web-fetch("https://github.com/{owner}/{repo}/issues/{number}")`
  - `web-fetch("https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}")`
- **❌ NEVER** scrape remote GitHub web pages for data
- **❌ NEVER** parse HTML from remote GitHub when API data is available

**Required Patterns (ALWAYS DO THIS)**:
- **✅ ALWAYS** use `github-api` tool for remote GitHub data:
  - `github-api` with `path="/repos/{owner}/{repo}/pulls/{number}"`
  - `github-api` with `path="/repos/{owner}/{repo}/issues/{number}"`
  - `github-api` with `path="/repos/{owner}/{repo}/contents/{path}"` for remote file contents
- **✅ ALWAYS** use query parameters for filtering (e.g., `state=open`, `author=@me`)
- **✅ ALWAYS** use search endpoints for complex queries

**Examples**:
```python
# ✅ Correct - Use github-api tool for remote GitHub resources
github-api(path="/repos/{owner}/{repo}/pulls", data={"state": "open", "head": "user:branch-name"})
github-api(path="/search/issues", data={"q": "is:pr author:@me repo:{owner}/{repo}"})
github-api(path="/repos/{owner}/{repo}/contents/path/to/file.py")

# ❌ Incorrect - Don't use web-fetch for remote GitHub resources
web-fetch("https://github.com/{owner}/{repo}/pull/123")
web-fetch("https://raw.githubusercontent.com/{owner}/{repo}/main/file.py")

# ⚠️ Fallback - Use gh CLI only when github-api cannot do it
# (Must document why github-api cannot be used)
gh pr view 123 --json body,comments
```

**Benefits of `github-api` Tool**:
- **Authentication**: Uses proper GitHub API authentication automatically
- **Structured data**: Returns JSON/YAML data instead of HTML
- **Rate limiting**: Handles API rate limits appropriately
- **Filtering**: Supports powerful query parameters for efficient data retrieval
- **Completeness**: Access to all GitHub API endpoints
- **Consistency**: Uniform interface for all GitHub operations

## Notes Management (Living Documentation System)

> Notes are managed using the basic-memory tools (`write_note`, `search_notes`, `read_note`, `build_context`, `recent_activity`, etc.)

### CRITICAL: Mandatory Notes Triggers

**These triggers are enforced at CRITICAL priority. Skipping them is a violation.**

#### Session Start (MUST check basic-memory)
When the user's first message involves ANY of these, IMMEDIATELY call `recent_activity` and/or `search_notes`:
- A named project, repository, or codebase
- A topic previously discussed (architecture, patterns, decisions)
- References to "we did", "last time", "before", or similar prior work
- Technical decisions or design questions

**Failure mode**: Proceeding without checking basic-memory when context likely exists.

#### Task Completion (MUST consider notes update)
After completing ANY of these, explicitly evaluate whether notes need updating:
- Implementing a feature or fixing a non-trivial bug
- Making an architectural or design decision
- Discovering how something works (debugging, investigation)
- Setting up infrastructure, environments, or tooling
- Resolving a problem that took significant effort

**Required action**: Either update relevant notes OR explicitly state "No notes update needed because [reason]."

#### End of Session Checklist
Before ending a substantive work session, review:
1. **New knowledge**: Did we learn anything worth preserving?
2. **Changed decisions**: Did any documented decisions change?
3. **Stale notes**: Did we encounter outdated information in notes?
4. **Patterns discovered**: Did we establish patterns worth documenting?

**If any answer is "yes"**: Update notes before concluding.

### Purpose: Living Documentation

**Rule**: Basic-memory serves as living documentation of the user's projects, choices, and reasoning. It must be treated as both a primary reference source AND an actively maintained knowledge base.

**Core Principles**:
1. **Reference First**: Consult basic-memory before starting work on any project or topic
2. **Maintain Actively**: Keep notes up-to-date as decisions are made and understanding evolves
3. **Capture Reasoning**: Document not just what was done, but WHY - the choices, tradeoffs, and context
4. **Evolve Continuously**: Notes are living documents that should be updated, not just appended to

### Session Initialization: Consult Basic-Memory First

**Rule**: At the start of any work session involving a project, codebase, or topic that may have prior context, the AI assistant MUST check basic-memory for relevant information.

**Implementation**:
1. **Search for context**: Use `search_notes` or `build_context` to find relevant prior notes
2. **Check recent activity**: Use `recent_activity` to see what has been documented recently
3. **Apply prior knowledge**: Use discovered context to inform the current session

**When to consult basic-memory**:
- Starting work on any named project or repository
- Revisiting a topic that was previously discussed
- Making architectural or design decisions
- Before suggesting approaches to problems
- When the user references prior work or decisions

**Example initialization patterns**:
```
User: "Let's work on the data-pipeline project"
AI: (Internally) Search basic-memory for "data-pipeline" to find prior context,
    decisions, patterns, and any documented issues or preferences.

User: "How should we handle authentication?"
AI: (Internally) Check if there are notes about authentication decisions or
    patterns before suggesting an approach.
```

### Proactive Knowledge Preservation

**Rule**: The AI assistant must proactively consider updating notes throughout all work sessions, rather than only storing information when explicitly requested.

**Rationale**: Valuable insights, patterns, and decisions discovered during development sessions are often lost when not captured. Proactive notes management creates a persistent, searchable collection that improves AI effectiveness in future sessions and provides standalone documentation value for the user.

### When to Update Notes

The AI assistant should actively consider storing information in notes after:

1. **Completing significant work**:
   - Implementing a new feature or fixing a complex bug
   - Setting up new infrastructure, services, or development environments
   - Completing a refactoring effort or architectural change
   - Resolving a challenging debugging session

2. **Learning new patterns**:
   - Discovering how a particular system or codebase works
   - Understanding project-specific conventions or workflows
   - Finding effective approaches to recurring problems
   - Identifying anti-patterns or pitfalls to avoid

3. **Discovering useful information**:
   - Finding undocumented APIs, configurations, or system behaviors
   - Identifying dependencies between components
   - Uncovering historical context or design rationale
   - Locating important resources or reference materials

4. **Observing team dynamics and expertise**:
   - Reviewing PRs that reveal someone's particular expertise or working style
   - Collaborating on code that shows effective patterns or complementary skills
   - Code review interactions that demonstrate consistent strengths or knowledge areas
   - Project work that reveals informal leadership or ownership patterns

5. **Discovery and Investigation** (CRITICAL):
   - When locating where functionality is implemented in a codebase (e.g., "found that user authentication is handled in `auth/providers.py`")
   - When discovering what data or capabilities are available through an API, database, or external service
   - When mapping out system architecture or component relationships during exploration
   - When identifying undocumented behaviors, quirks, or constraints of a system
   - When reverse-engineering how existing code works

   **Rationale**: These discoveries represent valuable knowledge that prevents redundant investigation in future sessions. Documenting "where things are" and "what's available" creates a searchable map of the codebase and its integrations.

   **What to capture**:
   - Location of key functionality (file paths, class/function names)
   - Available API endpoints, parameters, and response structures
   - Database schemas, available tables, and key relationships
   - External service capabilities and integration patterns
   - System behaviors that weren't obvious from documentation

### What Types of Information to Store

**Technical patterns and solutions**:
- Architectural decisions and their rationale
- Code patterns that work well in this codebase
- Solutions to complex technical challenges
- Integration patterns between services or systems
- Performance optimizations and their context

**Project-specific configurations**:
- Development environment setup procedures
- Build and deployment workflows
- Testing strategies and patterns
- Tool configurations and their purposes
- Environment-specific settings and variables

**Debugging insights**:
- Root causes of tricky bugs and how they were identified
- Troubleshooting approaches that proved effective
- Common error patterns and their solutions
- System behaviors that caused confusion initially

**User preferences and standards**:
- Coding style preferences observed during collaboration
- Preferred tools, libraries, and approaches
- Review feedback patterns and expectations
- Communication preferences and workflows

**Standalone documentation**:
- API documentation and usage examples
- System architecture overviews
- Onboarding information for new contributors
- Decision logs and change histories
- Notes that have reference value independent of AI assistance

**Team member insights and collaboration patterns**:
- Individual strengths, expertise areas, and technical specializations observed during code reviews
- Working styles and preferences discovered through PR interactions and collaboration
- Project ownership and responsibility areas identified through commit history and code contributions
- Communication patterns and preferred collaboration methods
- Areas where team members consistently provide valuable input or catch important issues
- Technical mentoring relationships and knowledge transfer patterns
- Domain expertise mapping (who knows what systems/technologies best)

**Privacy considerations for team information**:
- Focus exclusively on professional capabilities and working patterns
- Store only information relevant to effective collaboration and project success
- Avoid personal information, opinions, or subjective assessments of character
- Frame observations positively (strengths and expertise, not weaknesses)
- Information should be factual and based on observable work patterns
- When in doubt, ask the user before storing team-related information

### Storage Criteria

Information should be stored in notes if it meets **either** criterion:

1. **Future AI utility**: Would help the AI assistant work more effectively in future sessions
   - Reduces need to re-discover information
   - Enables faster context building
   - Prevents repeating past mistakes
   - Supports more informed decision-making

2. **Standalone value**: Serves as useful documentation, notes, or reference material for the user
   - Has value even without AI involvement
   - Would be useful for team members or future maintainers
   - Captures institutional knowledge
   - Provides searchable reference material

### Documenting Choices and Reasoning

**Rule**: Notes should capture not just WHAT was done, but WHY - the context, alternatives considered, tradeoffs, and reasoning behind decisions.

**Why document reasoning**:
- Future sessions can understand the constraints that led to a decision
- Prevents re-litigating decisions that were already carefully considered
- Allows revisiting decisions when circumstances change
- Creates institutional memory that survives context switches

**What to capture**:
- The problem or need that prompted the decision
- Alternatives that were considered
- Tradeoffs between the options
- Why the chosen approach was selected
- Any constraints or assumptions that influenced the choice
- Known limitations or future considerations

**Example decision documentation**:
```
Decision: Use DuckDB for local analytics instead of PostgreSQL

Context: Need embedded analytics for the data pipeline project

Alternatives considered:
1. SQLite - Simpler but lacks columnar storage for analytics workloads
2. PostgreSQL - Full-featured but requires external server management
3. DuckDB - Embedded, columnar, excellent pandas integration

Why DuckDB:
- No server management overhead for development environments
- Native parquet and pandas support fits our data workflow
- Columnar storage provides good performance for our analytical queries
- Easy migration path to cloud data warehouses later

Tradeoffs accepted:
- Less mature than PostgreSQL for production workloads
- Smaller community and fewer resources for troubleshooting

Future considerations:
- May need to migrate to cloud warehouse for production scale
- Monitor for concurrent write limitations
```

### Keeping Notes Current (Living Documentation)

**Rule**: Notes must be treated as living documents that evolve with the project. Outdated notes are worse than no notes - they create confusion and waste time.

**Update triggers**:
- When a documented decision is revised or reversed
- When new information invalidates previous understanding
- When project architecture or patterns change
- When dependencies or tools are upgraded
- When documented problems are solved or become irrelevant

**Update workflow**:
1. Before making changes, check if relevant notes exist
2. After completing significant work, review related notes for accuracy
3. Use `edit_note` to update existing notes rather than creating duplicates
4. Add dated entries for major changes to preserve history when appropriate

**Proactive maintenance prompts**:
- "I notice the notes about [topic] may be outdated based on our current work. Should I update them?"
- "This change affects the documented architecture. Let me update the relevant notes."
- "The approach documented in [note] has evolved. I'll update it to reflect current practice."

**Version tracking in notes**:
- For significant changes, consider adding a "History" or "Changelog" section
- Note when major decisions were made or revised
- Reference related decisions or dependent notes

### Implementation Guidelines

**Active consideration**: At natural transition points in work sessions, the AI should explicitly consider whether valuable information has been generated that warrants storage:
- "This debugging session revealed important insights about [system]. Should I store this in notes for future reference?"
- "The approach we used to solve [problem] might be useful to document. Would you like me to add it to notes?"

**Proactive suggestions**: When significant work is completed, the AI should mention if information appears worth preserving:
- "I've completed the implementation. The architectural pattern we used here might be worth documenting in notes for future sessions."
- "This configuration took some trial and error to get right. I can store the working setup in notes if that would be helpful."

**Organization**: Use meaningful folder structures and note titles that facilitate future retrieval:
- Group related information logically
- Use descriptive titles that indicate content
- Include relevant tags for searchability
- Cross-reference related notes when appropriate

**Content quality**: Ensure stored information is:
- Clear and understandable without additional context
- Accurate and up-to-date
- Actionable where applicable
- Appropriately detailed for its purpose

### What NOT to Store

Avoid storing information that:
- Is trivial or easily re-discoverable
- Contains sensitive credentials or secrets
- Is highly volatile and likely to become stale quickly
- Duplicates information already well-documented elsewhere
- Is specific to a single, one-off task with no future relevance

### Examples of Good Storage Opportunities

```
✅ "After debugging for an hour, discovered that the auth service requires
   specific header formatting that isn't documented. Should store this."

✅ "The deployment process required several non-obvious steps. Worth
   documenting for future reference."

✅ "User prefers explicit error handling over broad try/except. Should
   note this coding preference."

✅ "Found that performance issues were caused by N+1 queries in this
   pattern. Good to document the fix approach."

✅ "Sarah's PR reviews consistently catch edge cases in error handling.
   She has deep expertise in the payments system and auth flows."

✅ "Alex is the go-to person for Kubernetes and infrastructure questions.
   He authored most of the Helm charts and deployment pipelines."

✅ "Code reviews show that the backend team prefers async discussions
   on complex PRs before scheduling sync meetings."

❌ "Ran 'git status' to check file changes." (too trivial)

❌ "Fixed a typo in variable name." (too minor, no future value)

❌ "API key is xyz123..." (contains secrets)

❌ "John seems disorganized and often misses meetings." (personal/negative)

❌ "Maria is difficult to work with." (subjective character assessment)
```
