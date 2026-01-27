---
type: agent_requested
priority: STANDARD
description: Guidelines for refactoring, code maintenance, and technical debt management
last_updated: 2025-01-26
---

# Refactoring and Maintenance Guidelines

## ⚠️ Refactoring Scope and Authorization Policy ⚠️

### Scope Limits

**Small refactoring (can proceed without explicit permission):**
- Renaming variables/functions within a single file
- Extracting small functions (< 10 lines)
- Simplifying conditional logic in one function
- Removing unused imports or variables
- Fixing code style issues

**Medium refactoring (requires user confirmation):**
- Refactoring multiple related functions
- Changing function signatures
- Restructuring a single class
- Moving code between files
- Changes affecting 50-200 lines

**Large refactoring (requires detailed plan and approval):**
- Refactoring multiple files or modules
- Changing public APIs
- Restructuring class hierarchies
- Consolidating or splitting modules
- Changes affecting > 200 lines

### Authorization Workflow

**For medium refactoring:**
```
I will refactor the following:

Files affected: [list]
Changes:
- [specific changes]

Estimated impact: ~150 lines changed

This refactoring will:
- [benefits]
- [potential risks]

Proceed? (yes/no)
```

**For large refactoring:**
```
LARGE REFACTORING PLAN

Scope:
- [detailed scope]

Files affected: [list with line counts]
Estimated changes: ~500 lines

Plan:
1. [step 1]
2. [step 2]
3. [step 3]

Risks:
- [potential issues]

Testing strategy:
- [how to verify]

This is a significant change. Would you like me to:
1. Proceed with full refactoring
2. Break into smaller steps
3. Start with a proof-of-concept
4. Cancel

Your choice:
```

### Refactoring Boundaries

**NEVER refactor without explicit permission:**
- Public APIs used by external code
- Database schema or migrations
- Configuration file formats
- Build or deployment scripts
- Code in other repositories

**When user says "improve code quality" or "refactor this":**
1. Analyze scope of changes needed
2. Present specific refactoring plan
3. Wait for approval before proceeding
4. If scope is large, offer to break into smaller steps

---

## Refactoring Principles

### Systematic Refactoring Approach
- **Rule**: Approach refactoring systematically with clear goals and measurable outcomes
- **Rationale**: Based on observed pattern of comprehensive refactoring in pytest plugin
- **Implementation**: 
  - Identify specific problems before starting refactoring
  - Break large refactoring into smaller, reviewable chunks
  - Maintain functionality while improving structure
  - Document architectural decisions and trade-offs

### Consolidation Over Fragmentation
- **Rule**: Prefer consolidating related functionality over creating multiple small modules
- **Rationale**: Reduces cognitive overhead and maintenance burden
- **Implementation**: 
  - Merge similar classes or functions with overlapping responsibilities
  - Eliminate duplicate logic patterns across the codebase
  - Create unified interfaces for related operations
  - Reduce the number of configuration options and parameters

### Remove Before Adding
- **Rule**: Always look for opportunities to remove code before adding new functionality
- **Implementation**: 
  - Remove unused code, imports, and dependencies
  - Eliminate redundant processing steps or data transformations
  - Simplify complex conditional logic
  - Remove configuration options that serve only edge cases

## Technical Debt Management

### Identify and Document Technical Debt
- **Rule**: Actively identify and document technical debt with clear remediation plans
- **Implementation**: 
  - Use TODO comments with specific improvement suggestions
  - Document architectural decisions that create technical debt
  - Track technical debt in issue tracking systems
  - Prioritize technical debt based on impact and effort

### Incremental Improvement
- **Rule**: Make incremental improvements to code quality with each change
- **Implementation**: 
  - Apply the "boy scout rule" - leave code better than you found it
  - Refactor code you're modifying as part of feature work
  - Improve test coverage when working in untested areas
  - Update documentation when making related changes

### Legacy Code Handling
- **Rule**: Handle legacy code with care while planning for modernization
- **Implementation**: 
  - Understand existing behavior before making changes
  - Add tests for legacy code before refactoring
  - Modernize APIs gradually while maintaining backward compatibility
  - Document legacy patterns and migration strategies

## Code Quality Improvement

### Complexity Reduction Strategies
- **Rule**: Actively work to reduce code complexity and cognitive load
- **Implementation**: 
  - Break large functions into smaller, focused functions
  - Reduce nesting levels through early returns and guard clauses
  - Simplify conditional logic using lookup tables or polymorphism
  - Extract complex expressions into well-named variables

### API Simplification
- **Rule**: Continuously simplify and improve API design
- **Implementation**: 
  - Reduce the number of required parameters through sensible defaults
  - Combine related operations into single, more powerful methods
  - Hide implementation details behind clean abstractions
  - Provide convenience methods for common use cases

### Error Handling Improvement
- **Rule**: Improve error handling and debugging capabilities during refactoring
- **Implementation**: 
  - Replace generic exceptions with specific, meaningful exception types
  - Add context information to error messages
  - Implement consistent logging patterns
  - Provide clear error recovery mechanisms where appropriate

## Testing During Refactoring

### Test-Driven Refactoring
- **Rule**: Use tests to guide and validate refactoring efforts
- **Implementation**: 
  - Write tests for existing behavior before refactoring
  - Use tests to verify that refactoring preserves functionality
  - Improve test quality and coverage during refactoring
  - Remove or update obsolete tests after refactoring

### Regression Prevention
- **Rule**: Implement comprehensive regression testing for refactored code
- **Implementation**: 
  - Run full test suite after each refactoring step
  - Add integration tests for complex refactoring scenarios
  - Test edge cases and error conditions thoroughly
  - Validate performance characteristics after refactoring

## Documentation and Communication

### Document Refactoring Decisions
- **Rule**: Document the rationale and impact of significant refactoring efforts
- **Implementation**: 
  - Explain the problems that refactoring solves
  - Document new patterns and conventions introduced
  - Provide migration guides for API changes
  - Include performance and maintainability improvements

### Communicate Changes Effectively
- **Rule**: Communicate refactoring changes clearly to team members
- **Implementation**: 
  - Write detailed pull request descriptions explaining changes
  - Highlight breaking changes and migration requirements
  - Provide examples of new usage patterns
  - Include lessons learned and future improvement opportunities

### Knowledge Transfer
- **Rule**: Use refactoring as an opportunity for knowledge transfer
- **Implementation**: 
  - Include team members in refactoring planning and review
  - Document patterns and anti-patterns discovered during refactoring
  - Share refactoring techniques and tools with the team
  - Create coding standards based on refactoring insights
