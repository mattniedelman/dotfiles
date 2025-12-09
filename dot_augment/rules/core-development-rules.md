---
type: always_apply
description: Core development rules and coding standards for Matt's workflow
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

## Mandatory Code Patterns

### Prohibit Continue Statements
- **Rule**: Never use `continue` statements in loops
- **Rationale**: Continue statements create hidden control flow that makes code harder to follow and debug
- **Alternatives**: 
  - Use early returns in functions
  - Restructure loops with proper conditionals
  - Extract loop body into separate functions
  - Use filter() or list comprehensions for data processing

### Import Organization
- **Rule**: All library imports must be placed at the top of files, immediately after file headers/docstrings
- **Exception**: Only deviate when explicitly requested for specific technical requirements
- **Structure**: 
  1. Standard library imports
  2. Third-party imports  
  3. Local application imports
  4. Separate groups with blank lines

### No Nested Functions or Closures
- **Rule**: **NEVER** define functions inside other functions, **NEVER** define classes inside functions, and **NEVER** create closures
- **Scope**: This prohibition applies to ALL Python code without exception:
  - **NEVER** use `def` to define a function inside another function
  - **NEVER** use `def` to define a function inside a class method that captures variables from the method scope
  - **NEVER** define classes inside functions
  - **NEVER** create lambda expressions that capture variables from enclosing scopes (closures)
  - **NEVER** use nested functions even for "helper" functions, callbacks, or decorators
- **Exception**: Only when the user **explicitly requests** nested functions or closures for a specific technical requirement and provides clear justification
- **Rationale**:
  - Nested functions dramatically increase code complexity and cognitive load
  - Closures create hidden dependencies that are difficult to understand and debug
  - Nested functions cannot be tested in isolation, reducing test coverage and quality
  - Code with nested functions is harder to refactor and maintain
  - Nested functions obscure the true dependencies and data flow of the code
  - Module-level functions with explicit parameters are always clearer and more testable
- **Alternatives**:
  - **Use class methods for stateful behavior**: If a function needs to maintain state or access instance data, make it a method of a class
  - **Pass parameters explicitly**: Instead of capturing variables from outer scopes, pass them as explicit function parameters
  - **Create separate module-level functions**: Define functions at module level (top-level of the file) rather than nesting them
  - **Use classes for related functionality**: Group related functions as methods of a class rather than nesting them
  - **Extract to private module functions**: Use leading underscore naming (e.g., `_helper_function`) for module-level functions that are implementation details
- **Examples**:
  ```python
  # ❌ PROHIBITED - Nested function
  def outer_function(x):
      def inner_function(y):
          return x + y
      return inner_function(5)

  # ❌ PROHIBITED - Closure with lambda
  def create_multiplier(factor):
      return lambda x: x * factor

  # ❌ PROHIBITED - Class defined inside function
  def create_handler():
      class Handler:
          def handle(self):
              pass
      return Handler()

  # ✅ CORRECT - Module-level function with explicit parameters
  def inner_function(x, y):
      return x + y

  def outer_function(x):
      return inner_function(x, 5)

  # ✅ CORRECT - Class method for stateful behavior
  class Multiplier:
      def __init__(self, factor):
          self.factor = factor

      def multiply(self, x):
          return x * self.factor

  def create_multiplier(factor):
      return Multiplier(factor)

  # ✅ CORRECT - Class defined at module level
  class Handler:
      def handle(self):
          pass

  def create_handler():
      return Handler()
  ```

## Tool Selection Hierarchy

### ⚠️ MANDATORY: Use Specialized Tools Over Generic Search ⚠️

- **Rule**: **ALWAYS** use the most precise and specialized tool available for each task type. This is a mandatory requirement with **NO EXCEPTIONS** unless specialized tools are genuinely unavailable.
- **Enforcement**: Violation of this rule is a **CRITICAL FAILURE**. Using generic text search tools (`grep`, `ripgrep`, `ag`, `ack`, etc.) for code symbol searches when specialized tools are available is unacceptable.
- **Rationale**: Specialized code analysis tools understand language syntax, scope, and semantics, providing more accurate results than text-based search. They reduce false positives and ensure all actual references are found, including those that might be missed by simple text matching. Using the wrong tool leads to incomplete results, missed references, and potential bugs.
- **Implementation**:
  - **ALWAYS use language-aware tools** that understand code structure over text-based search tools
  - **ALWAYS use semantic analysis tools** for code symbols, references, definitions, and implementations
  - **ONLY use generic text search** for non-code content or when specialized tools are genuinely unavailable
  - **NEVER use grep/ripgrep/ag/ack** for searching code symbols when semantic tools exist

### Code Analysis Tool Priority (MANDATORY)
- **Rule**: **MUST** use specialized code analysis tools instead of generic text search when working with code symbols
- **Absolute Requirement**: Before using ANY search tool, you MUST determine if you are searching for a code symbol. If yes, you MUST use semantic analysis tools.
- **Tool Selection Guidelines** (in strict priority order):
  1. **REQUIRED for code symbols**: Use semantic code analysis tools
     - `find_symbol` - Locate symbol definitions by name or pattern
     - `find_referencing_symbols` - Find all usages of a class, function, or variable
     - `find_definition` - Locate where a symbol is defined
     - `find_implementations` - Find all implementations of an interface or abstract class
     - `get_symbols_overview` - Get high-level understanding of symbols in a file
  2. **Second choice**: Use language-specific tools when available
     - Language servers and LSP-based tools
     - AST-based analysis tools
     - IDE-integrated search features
  3. **ONLY when genuinely unavailable**: Use generic text search ONLY when:
     - Searching for non-code content (documentation, comments, configuration values)
     - Searching for string literals or text patterns
     - Specialized tools are genuinely not available for the language
     - The search target is definitively not a code symbol
     - **You MUST justify why semantic tools cannot be used before falling back to text search**

### Correct Tool Selection Examples
- **✅ Correct - Use semantic analysis for code symbols**:
  - Use `find_referencing_symbols` to find all usages of a class, function, or variable
  - Use `find_symbol` to locate where a class or function is defined
  - Use `find_implementations` to find all implementations of an interface or abstract class
  - Use `get_symbols_overview` to understand the structure of a file before making changes

- **❌ Incorrect - Don't use text search for code symbols**:
  - Don't use `grep` or `ripgrep` to search for class names
  - Don't use `ag` or `ack` to find function calls
  - Don't use text search to locate variable references
  - Don't use regex patterns to find method implementations

### When Generic Search Is Appropriate
- **Rule**: Generic text search tools are appropriate only for specific use cases
- **Appropriate uses of `grep`, `ripgrep`, `ag`, etc.**:
  - Searching for TODO comments or documentation notes
  - Finding configuration values in YAML, JSON, or INI files
  - Locating string literals or error messages
  - Searching in non-code files (Markdown, text files, logs)
  - Finding patterns in data files or output
  - Searching across file types not supported by semantic tools

### Tool Selection Decision Tree
```
Need to search for something?
│
├─ Is it a code symbol (class, function, variable, method)?
│  ├─ YES → Use semantic code analysis tools (find_symbol, find_referencing_symbols, etc.)
│  └─ NO → Continue to next question
│
├─ Is it in a code file but not a symbol (comment, string literal, documentation)?
│  ├─ YES → Use view tool with search_query_regex or generic text search
│  └─ NO → Continue to next question
│
└─ Is it in a non-code file (config, documentation, data)?
   └─ YES → Use generic text search (grep, ripgrep, ag)
```

### Benefits of Specialized Tools
- **Accuracy**: Understand language syntax and avoid false positives from comments or strings
- **Completeness**: Find all references including those with different formatting or across files
- **Context**: Provide symbol type, scope, and relationship information
- **Refactoring safety**: Enable safe renames and refactoring by finding all true references
- **Performance**: Optimized for code analysis with indexed symbol databases

### Verification and Compliance
- **Rule**: Before executing any search operation, you MUST verify you are using the correct tool
- **Pre-Search Checklist** (MANDATORY):
  1. **Identify the target**: What am I searching for?
  2. **Classify the target**: Is it a code symbol (class, function, variable, method, interface)?
  3. **Select the tool**:
     - If code symbol → MUST use semantic analysis tools
     - If non-code content → May use generic text search
  4. **Verify availability**: Are semantic tools available for this language/project?
     - If YES → MUST use them (no exceptions)
     - If NO → Document why and justify text search usage
- **Self-Correction**: If you catch yourself about to use `grep`, `ripgrep`, `ag`, or `ack` for code symbols, STOP and switch to the appropriate semantic tool
- **Accountability**: Using the wrong tool type is considered a critical error in task execution

### Prohibited Patterns (NEVER DO THIS)
- **❌ NEVER** use `grep -r "class ClassName"` to find class definitions
- **❌ NEVER** use `ripgrep "def function_name"` to find function definitions
- **❌ NEVER** use `ag "import.*ModuleName"` to find import statements
- **❌ NEVER** use text search to find "all usages of" any code symbol
- **❌ NEVER** use regex patterns to locate method calls or variable references
- **❌ NEVER** justify text search for code symbols with "it's faster" or "it's simpler"

### Required Patterns (ALWAYS DO THIS)
- **✅ ALWAYS** use `find_symbol` to locate class, function, or variable definitions
- **✅ ALWAYS** use `find_referencing_symbols` to find all usages of a symbol
- **✅ ALWAYS** use `find_implementations` to find interface/abstract class implementations
- **✅ ALWAYS** use `get_symbols_overview` before making changes to understand file structure
- **✅ ALWAYS** verify semantic tools are truly unavailable before considering text search
- **✅ ALWAYS** document justification if forced to use text search for code

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
- **Rule**: Use type hints for all public functions and class methods
- **Rationale**: Improves code clarity and enables better tooling support
- **Documentation**: Include docstrings for all public APIs explaining purpose, parameters, and return values

### Error Handling Consistency
- **Rule**: Use consistent error handling patterns throughout the codebase
- **Implementation**:
  - Prefer specific exception types over generic Exception
  - Include meaningful error messages with context
  - Use logging consistently (avoid mixing print, console.print, etc.)
  - Return appropriate error codes and status information

### Modern Python Idioms
- **Rule**: Use modern Python features and idioms for cleaner, more maintainable code
- **Examples**:
  - Use pathlib for file operations
  - Prefer f-strings for string formatting
  - Use dataclasses or Pydantic models for structured data
  - Leverage context managers for resource management

### Comment Placement
- **Rule**: Write comments on their own line(s) above the code they describe, rather than at the end of a line of code
- **Rationale**: Standalone comments are easier to read, don't cause line length issues, and provide better context by appearing before the code they explain
- **Examples**:
  ```python
  # ✅ Preferred - Standalone comment
  # Calculate the weighted average based on user preferences
  result = sum(value * weight for value, weight in zip(values, weights)) / sum(weights)

  # ❌ Discouraged - Inline comment
  result = sum(value * weight for value, weight in zip(values, weights)) / sum(weights)  # Calculate weighted average

  # ✅ Preferred - Multi-line explanation
  # Convert UTC timestamp to local timezone and format as ISO 8601.
  # This ensures consistency across different deployment environments.
  local_time = utc_timestamp.astimezone(local_tz).isoformat()

  # ❌ Discouraged - Inline comment that causes line length issues
  local_time = utc_timestamp.astimezone(local_tz).isoformat()  # Convert to local timezone and format as ISO 8601
  ```
- **Exceptions**: Inline comments may be acceptable in these limited cases:
  - Very brief clarifications of complex expressions where the comment is shorter than the code
  - Type hints or annotations that are part of the syntax
  - When explicitly requested by the user for a specific purpose
  - Temporary debugging comments (which should be removed before committing)

## Package Management

### Python Package Manager Selection
- **Rule**: Always use `uv` as the default package manager for Python projects unless `poetry.lock` is explicitly present
- **Rationale**: `uv` is faster, more modern, and provides better dependency resolution. Only use Poetry when a project has already committed to it
- **Implementation**:
  1. **Check for lock files before choosing a package manager**:
     - If `poetry.lock` exists in the project root: use Poetry
     - If `uv.lock` exists OR no lock file exists: use `uv`
  2. **Use the correct commands for each package manager**:
     - **uv (default)**:
       - `uv run <command>` instead of `poetry run <command>`
       - `uv add <package>` instead of `poetry add <package>`
       - `uv remove <package>` instead of `poetry remove <package>`
       - `uv sync` to install dependencies
     - **Poetry (only when poetry.lock exists)**:
       - `poetry run <command>`
       - `poetry add <package>`
       - `poetry remove <package>`
       - `poetry install` to install dependencies
  3. **Never assume Poetry is the package manager** - always verify by checking for lock files first
  4. **When in doubt, default to `uv`** - it's the preferred modern solution

### General Package Management Best Practices
- **Rule**: Always use appropriate package managers for dependency management instead of manually editing package configuration files
- **Rationale**: Package managers automatically resolve correct versions, handle dependency conflicts, update lock files, and maintain consistency across environments. Manual editing of package files often leads to version mismatches, dependency conflicts, and broken builds
- **Implementation**:
  1. **Always use package manager commands** for installing, updating, or removing dependencies rather than directly editing files like package.json, requirements.txt, Cargo.toml, go.mod, etc.
  2. **Use the correct package manager commands** for each language/framework:
     - **JavaScript/Node.js**: Use `npm install`, `npm uninstall`, `yarn add`, `yarn remove`, or `pnpm add/remove`
     - **Python**: Use `uv add`, `uv remove` (preferred) or `poetry add`, `poetry remove` (when poetry.lock exists)
     - **Rust**: Use `cargo add`, `cargo remove` (Cargo 1.62+)
     - **Go**: Use `go get`, `go mod tidy`
     - **Ruby**: Use `gem install`, `bundle add`, `bundle remove`
     - **PHP**: Use `composer require`, `composer remove`
     - **C#/.NET**: Use `dotnet add package`, `dotnet remove package`
     - **Java**: Use Maven (`mvn dependency:add`) or Gradle commands
  3. **Exception**: Only edit package files directly when performing complex configuration changes that cannot be accomplished through package manager commands (e.g., custom scripts, build configurations, or repository settings)

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
- **Rule**: Never compare boolean expressions to boolean literals (`True` or `False`) in assertions
- **Rationale**: Comparing a boolean expression to a boolean literal is redundant, less readable, and provides no additional value. It forces readers to parse an unnecessary comparison operation and requires extra variable declarations that don't add clarity
- **Implementation**:
  - Assert boolean expressions directly: `assert condition` instead of `assert condition == True`
  - Use negation for false conditions: `assert not condition` instead of `assert condition == False`
  - This applies to all assertion contexts, including pytest assertions and other testing frameworks
- **Examples**:
  ```python
  # ❌ Incorrect - Comparing boolean expression to boolean literal
  expected_is_different_instance = True
  assert (filtered is not original) == expected_is_different_instance
  
  expected_is_smaller = True
  assert (len(filtered) < len(original)) == expected_is_smaller
  
  # ❌ Incorrect - Direct comparison to boolean literal
  assert (user.is_active == True)
  assert (result.success == False)
  
  # ✅ Correct - Assert boolean expressions directly
  assert filtered is not original
  assert len(filtered) < len(original)
  assert user.is_active
  assert not result.success
  
  # ✅ Correct - When you need an expected value, use it for the actual comparison
  expected_count = 5
  assert len(filtered) == expected_count
  
  expected_status = "active"
  assert user.status == expected_status
  ```
- **Exception**: The only time to use an `expected_*` boolean variable is when the expected value is computed, comes from test data, or varies across parameterized tests. Even then, assert the expression directly rather than comparing to the variable:
  ```python
  # ✅ Acceptable when expected value is computed
  expected_is_valid = compute_expected_validity(test_case)
  assert is_valid == expected_is_valid  # Comparing actual boolean to expected boolean
  
  # ❌ Still incorrect - Don't compare expression to True
  assert (is_valid) == expected_is_valid  # Redundant parentheses and comparison
  ```

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

### Linting Error Resolution
- **Rule**: Always address linting errors by fixing the underlying issue rather than suppressing warnings
- **Rationale**: Linting errors indicate potential bugs, style inconsistencies, or maintainability issues. Suppressing them without fixing the root cause degrades code quality over time and can hide real problems
- **Implementation**:
  - **Never ignore or suppress linting errors** unless explicitly instructed by the user to do so
  - **Always attempt to fix linting errors** by making appropriate code changes that address the underlying issue
  - **Balance fixes with system stability** - don't introduce breaking changes or new bugs while fixing linting issues
  - **Prioritize proper fixes over suppressions** - refactor code, split long lines, add type hints, or restructure logic as needed

### When Linting Errors Cannot Be Fixed
- **Rule**: Follow a structured approval process before suppressing any linting error
- **Process**:
  1. **Explain the situation**: Describe to the user why the linting error exists and why it's difficult to address
  2. **Analyze consequences**: Explain the potential consequences of fixing it versus leaving it
  3. **Request explicit approval**: Ask the user for permission before adding any suppression
  4. **Document the suppression**: If approved, add an inline suppression comment that:
     - Uses the linter-specific syntax (e.g., `# noqa: E501` for flake8, `# type: ignore[error-code]` for mypy, `# ruff: noqa: RULE` for ruff)
     - Includes a brief explanation of why the suppression is necessary
     - References the specific linting rule being suppressed (not a blanket ignore)

### Appropriate Suppression Scenarios
- **Rule**: Only suppress linting errors in specific, justified cases with user approval
- **Examples of appropriate scenarios** (only with explicit user approval):
  - **Line length violations**: URLs or long string literals that cannot be reasonably split without breaking functionality
  - **Type checking issues**: Third-party libraries that lack proper type stubs or have incorrect type definitions
  - **False positives**: Intentional use of patterns that trigger false positives in specific, well-understood contexts
  - **Generated code**: Auto-generated code where manual fixes would be overwritten
  - **Performance-critical code**: Cases where the "correct" pattern has measurable performance implications
- **Examples of inappropriate suppressions** (should always be fixed instead):
  - Line length violations in regular code (refactor into multiple lines or extract to variables)
  - Missing type hints (add proper type annotations)
  - Unused imports or variables (remove them)
  - Style violations (fix the style to match project standards)
  - Complexity warnings (refactor to reduce complexity)

### Suppression Best Practices
- **Rule**: When suppressions are necessary and approved, follow these guidelines
- **Implementation**:
  - **Never use blanket suppressions**: Avoid `# noqa` without specifying the rule code, or `# type: ignore` without the specific error
  - **Be specific**: Always reference the exact linting rule being suppressed (e.g., `# noqa: E501` not just `# noqa`)
  - **Add context**: Include a brief comment explaining why the suppression is necessary
  - **Minimize scope**: Use inline suppressions for specific lines rather than file-level or block-level ignores
  - **Review regularly**: Suppressions should be revisited during refactoring to see if they can be removed
- **Examples**:
  ```python
  # ✅ Good - Specific suppression with explanation
  # This URL cannot be split without breaking the API endpoint
  VERY_LONG_API_URL = "https://api.example.com/v1/very/long/endpoint/path/that/cannot/be/shortened"  # noqa: E501

  # ✅ Good - Specific type ignore with context
  # Third-party library missing type stubs, tracked in issue #123
  result = external_library.process(data)  # type: ignore[no-untyped-call]

  # ❌ Bad - Blanket suppression without explanation
  result = some_function()  # noqa

  # ❌ Bad - Generic type ignore
  result = some_function()  # type: ignore

  # ❌ Bad - Should be fixed instead of suppressed
  very_long_line = first_value + second_value + third_value + fourth_value + fifth_value  # noqa: E501
  # Should be: Split into multiple lines or extract to variables
  ```

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
