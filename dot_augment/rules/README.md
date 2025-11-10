# Development Rules and Guidelines

This directory contains comprehensive coding rules and guidelines for Matt's development workflow, based on:

1. **Explicit Requirements**: Mandatory rules for code patterns and structure
2. **"A Philosophy of Software Design"**: Principles for managing complexity and building maintainable systems
3. **GitHub Activity Analysis**: Patterns derived from actual code review and development practices
4. **Modern Python Best Practices**: Current standards for Python development

## Rules Files Overview

### Core Development Rules (`core-development-rules.md`)
**Type**: `always_apply` - Applied to every interaction
- Mandatory code patterns (no continue statements, import organization, no nested functions)
- Deep modules and simple interfaces
- Complexity management principles
- Python-specific best practices
- Testing and quality standards
- Code organization guidelines

### API Design Patterns (`api-design-patterns.md`)
**Type**: `agent_requested` - Applied when working on APIs and services
- RESTful API design principles
- Client interface design patterns
- Service integration guidelines
- FastAPI specific patterns
- Authentication and configuration management

### Data Science and ML Patterns (`data-science-ml-patterns.md`)
**Type**: `agent_requested` - Applied when working on ML/data science code
- Model development and lifecycle management
- Data pipeline design principles
- Clustering and topic modeling patterns (BERTopic, etc.)
- Performance and scalability considerations
- ML-specific testing strategies
- Documentation and reproducibility requirements

### Refactoring and Maintenance (`refactoring-and-maintenance.md`)
**Type**: `agent_requested` - Applied during refactoring and maintenance work
- Systematic refactoring approaches
- Technical debt management strategies
- Code quality improvement techniques
- Testing during refactoring
- Documentation and communication guidelines

## Key Principles Summary

### From "A Philosophy of Software Design"
1. **Deep Modules**: Create modules with simple interfaces that hide complex functionality
2. **Information Hiding**: Hide implementation details behind clean abstractions
3. **General-Purpose Design**: Prefer general solutions over highly specialized ones
4. **Consistency**: Maintain consistent patterns for naming, error handling, and design
5. **Strategic Programming**: Think long-term about design decisions

### From GitHub Activity Analysis
1. **Consolidation Over Fragmentation**: Merge related functionality rather than creating many small modules
2. **Simplification**: Actively remove unnecessary complexity and redundant code
3. **Clear APIs**: Design intuitive interfaces that minimize cognitive load
4. **Comprehensive Testing**: Maintain high test coverage with clear, meaningful tests
5. **Detailed Documentation**: Provide thorough explanations of architectural decisions

### Mandatory Patterns
1. **No Continue Statements**: Use early returns or restructured logic instead
2. **Import Organization**: All imports at the top, properly grouped and ordered
3. **No Nested Functions**: Avoid closures and nested function definitions unless explicitly requested

## Usage with Augment

These rules are automatically loaded by Augment CLI and IDE extensions. The `always_apply` rules are included in every interaction, while `agent_requested` rules are automatically detected and applied when relevant to your current task.

To use a specific rule file manually in IDE extensions, you can reference it with `@` mentions in your prompts.

## Customization

Feel free to modify these rules as your preferences and project requirements evolve. The rules are designed to be:
- **Specific and Actionable**: Clear guidance on what to do and why
- **Context-Aware**: Different rules for different types of work
- **Evolution-Friendly**: Easy to update as practices change

## Contributing

When adding new rules or modifying existing ones:
1. Include clear rationale for the rule
2. Provide specific implementation guidance
3. Add examples where helpful
4. Consider the appropriate rule type (`always_apply` vs `agent_requested`)
5. Update this README if adding new rule files
