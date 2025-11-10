---
type: always_apply
description: Core development rules and coding standards for Matt's workflow
---

# Core Development Rules

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
- **Rule**: Avoid defining functions inside other functions or creating closures
- **Exception**: Only when explicitly requested for specific design patterns
- **Rationale**: Nested functions increase complexity and make testing difficult
- **Alternatives**: 
  - Use class methods for stateful behavior
  - Pass parameters explicitly
  - Create separate module-level functions

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

### Git Commits
- **Rule**: Only perform git commits when explicitly requested by the user
- **Rationale**: Committing code is a deliberate action that should be under the user's control and timing
- **Implementation**:
  - Never automatically commit changes after making edits
  - Never commit as part of a workflow unless specifically instructed
  - Ask for permission before committing if it seems appropriate
  - When asked to commit, use clear, descriptive commit messages that explain the changes

### Objective Language in Communication
- **Rule**: Never include subjective value judgments, self-congratulatory language, or promotional adjectives in git commit messages, code comments, documentation, or similar contexts
- **Rationale**: Objective, factual language maintains professionalism and focuses on what changed and why, rather than opinions about quality
- **Examples of prohibited language**:
  - Adjectives like "excellent", "amazing", "brilliant", "perfect", "beautiful", "elegant"
  - Self-promotional phrases like "greatly improved", "much better", "significantly enhanced"
  - Subjective assessments like "this is the best approach", "optimal solution", "superior implementation"
- **Preferred alternatives**:
  - Describe what changed: "Refactor authentication to use JWT tokens"
  - Explain why: "Fix race condition in user session handling"
  - State measurable improvements: "Reduce query time from 500ms to 50ms"
  - Use neutral language: "Simplify error handling logic" instead of "Greatly improve error handling"
- **Scope**: This applies to:
  - Git commit messages (both subject and body)
  - Inline code comments
  - Docstrings and documentation comments
  - Code review comments
  - Pull request descriptions
