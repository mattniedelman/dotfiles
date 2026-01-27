---
type: agent_requested
priority: STANDARD
description: API design patterns and interface guidelines for building maintainable services
last_updated: 2025-01-26
---

# API Design Patterns

## RESTful API Design

### Endpoint Structure
- **Rule**: Design RESTful endpoints that follow consistent patterns and naming conventions
- **Implementation**: 
  - Use nouns for resource names, not verbs
  - Use HTTP methods appropriately (GET, POST, PUT, DELETE)
  - Implement consistent query parameter patterns
  - Provide clear, hierarchical URL structures

### Response Consistency
- **Rule**: Maintain consistent response formats across all endpoints
- **Implementation**: 
  - Use standard HTTP status codes appropriately
  - Include consistent error response structures
  - Provide meaningful error messages with context
  - Use consistent data serialization formats

### Versioning Strategy
- **Rule**: Design APIs with evolution in mind from the start
- **Implementation**: 
  - Include version information in API design
  - Maintain backward compatibility when possible
  - Provide clear migration paths for breaking changes
  - Document API changes and deprecation timelines

## Client Interface Design

### Simple Client APIs
- **Rule**: Create client classes with intuitive, consolidated interfaces
- **Rationale**: Based on observed pattern of simplifying client interactions
- **Implementation**: 
  - Single client class per service with logical method grouping
  - Sensible defaults to minimize required parameters
  - Clear separation between configuration and operational methods
  - Consistent error handling across all client methods

### Data Transfer Objects
- **Rule**: Use well-defined DTOs for data exchange between services
- **Implementation**: 
  - Use Pydantic models for automatic validation and serialization
  - Include clear field documentation and examples
  - Implement proper type hints for all fields
  - Provide conversion methods between internal and external representations

### Configuration Management
- **Rule**: Centralize and standardize configuration handling across services
- **Implementation**: 
  - Use environment variables for deployment-specific settings
  - Provide configuration validation at startup
  - Document all configuration options with examples
  - Use configuration classes rather than scattered constants

## Service Integration Patterns

### Database Integration
- **Rule**: Abstract database operations behind clean interfaces
- **Implementation**: 
  - Use connection pooling and proper resource management
  - Implement consistent query patterns and error handling
  - Separate business logic from data access logic
  - Use modern database libraries (DuckDB, SQLAlchemy, etc.)

### External Service Integration
- **Rule**: Design resilient integrations with external services
- **Implementation**: 
  - Implement proper timeout and retry logic
  - Use circuit breaker patterns for unreliable services
  - Provide fallback mechanisms where appropriate
  - Log integration failures with sufficient context for debugging

### Authentication and Authorization
- **Rule**: Implement consistent security patterns across all services
- **Implementation**: 
  - Use standard authentication mechanisms (JWT, OAuth, etc.)
  - Implement proper session management
  - Validate permissions at appropriate service boundaries
  - Log security events for audit purposes

## FastAPI Specific Patterns

### Dependency Injection
- **Rule**: Use FastAPI's dependency injection system for clean separation of concerns
- **Implementation**: 
  - Create reusable dependencies for common functionality
  - Use dependency injection for database connections, authentication, etc.
  - Implement proper dependency lifecycle management
  - Test dependencies independently

### Request/Response Models
- **Rule**: Define explicit Pydantic models for all request and response data
- **Implementation**: 
  - Use descriptive model names that indicate their purpose
  - Include field validation and documentation
  - Implement proper error handling for validation failures
  - Use model inheritance to reduce duplication

### Middleware and Error Handling
- **Rule**: Implement consistent middleware for cross-cutting concerns
- **Implementation**: 
  - Use middleware for logging, authentication, and error handling
  - Implement global exception handlers for consistent error responses
  - Add request/response logging for debugging and monitoring
  - Include correlation IDs for request tracing
