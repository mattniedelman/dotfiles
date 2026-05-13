# ast-grep Rule Reference

Comprehensive documentation for writing ast-grep rules.

## Rule Structure

```yaml
id: rule-name  # Unique identifier
language: python  # Target language
rule:  # The matching rule (required)
  pattern: foo($ARG)
message: "Found foo call"  # Optional: shown in output
severity: warning  # Optional: error, warning, info, hint
fix: "bar($ARG)"  # Optional: auto-fix replacement
```

## Languages

Common language identifiers:
`python`, `javascript`, `typescript`, `tsx`, `rust`, `go`, `java`, `c`, `cpp`,
`ruby`, `bash`, `html`, `css`, `json`, `yaml`

## Pattern Syntax

### Metavariables

Capture any single AST node:

```yaml
# $NAME captures a single node
rule:
  pattern: console.log($ARG)

# $$$NAME captures multiple nodes (varargs)
rule:
  pattern: foo($$$ARGS)

# Unnamed metavar (match but don't capture)
rule:
  pattern: foo($_, $_)
```

### Wildcards

```yaml
# Match any expression
pattern: foo($EXPR)

# Match any statement sequence
pattern: |
  function $NAME() {
    $$$BODY
  }
```

## Atomic Rules

### pattern

Match a code pattern directly:

```yaml
rule:
  pattern: "x == None"
```

### kind

Match by AST node type:

```yaml
rule:
  kind: function_definition
```

Find valid kinds with:
`ast-grep run --pattern 'code' --lang python --debug-query=ast`

### regex

Match node text against a regex:

```yaml
rule:
  regex: "^TODO|FIXME"
```

### nthChild

Match nodes at a specific position:

```yaml
rule:
  nthChild: 1  # First child
  # or: "2n+1" for odd children
  # or: {position: 2, ofRule: {kind: argument}}
```

## Composite Rules

### all (AND)

All sub-rules must match:

```yaml
rule:
  all:
    - kind: function_definition
    - has:
        pattern: "return None"
        stopBy: end
```

### any (OR)

At least one sub-rule must match:

```yaml
rule:
  any:
    - pattern: "os.path.join($$$ARGS)"
    - pattern: "os.path.exists($ARG)"
```

### not (negation)

Matches when sub-rule does NOT match:

```yaml
rule:
  all:
    - kind: function_definition
    - not:
        has:
          pattern: "raise $ERROR"
          stopBy: end
```

## Relational Rules

**CRITICAL:
Always add `stopBy:
end` to relational rules** unless you specifically want to stop at a certain
depth.

### has (descendant)

Match nodes that contain a descendant matching the sub-rule:

```yaml
rule:
  kind: function_definition
  has:
    pattern: await $EXPR
    stopBy: end
```

Options:
- `stopBy:
  end` - Search all descendants (recommended default)
- `stopBy:
  neighbor` - Search only direct children
- `field:
  body` - Match only a specific named field

### inside (ancestor)

Match nodes that are inside an ancestor matching the sub-rule:

```yaml
rule:
  pattern: console.log($ARG)
  inside:
    kind: catch_clause
    stopBy: end
```

### follows (preceding sibling)

Match nodes that follow a sibling matching the sub-rule:

```yaml
rule:
  kind: return_statement
  follows:
    pattern: "x = $EXPR"
    stopBy: neighbor
```

### precedes (following sibling)

Match nodes that precede a sibling matching the sub-rule:

```yaml
rule:
  kind: import_statement
  precedes:
    kind: function_definition
    stopBy: neighbor
```

## Constraints

Constrain what metavariables can match:

```yaml
rule:
  pattern: $FUNC($ARG)
  constraints:
    FUNC:
      regex: "^(print|log|warn)$"
    ARG:
      kind: string
```

## Transforms

Transform captured metavariables in fixes:

```yaml
id: use-fstring
language: python
rule:
  pattern: "'{}'.format($ARG)"
fix: "f'{$ARG}'"
transform:
  ARG:
    substring:
      source: $ARG
      startChar: 0
```

## Multi-Rule Files

A YAML file can contain multiple rules:

```yaml
id: rule-one
language: python
rule:
  pattern: foo($ARG)
---
id: rule-two
language: python
rule:
  pattern: bar($ARG)
```

## Common Patterns

### Find function calls

```yaml
id: find-print-calls
language: python
rule:
  pattern: print($$$ARGS)
```

### Find async functions without error handling

```yaml
id: async-no-error-handling
language: javascript
rule:
  all:
    - kind: async_function
    - not:
        has:
          kind: try_statement
          stopBy: end
```

### Find class methods not calling super()

```yaml
id: missing-super-call
language: python
rule:
  all:
    - kind: function_definition
      has:
        field: name
        regex: "^__init__$"
    - inside:
        kind: class_definition
        stopBy: end
    - not:
        has:
          pattern: super().__init__($$$ARGS)
          stopBy: end
```

### Find deprecated API usage

```yaml
id: deprecated-api
language: python
rule:
  any:
    - pattern: os.path.join($$$ARGS)
    - pattern: os.path.exists($ARG)
    - pattern: os.path.dirname($ARG)
message: "Use pathlib instead of os.path"
```

### Find test functions without assertions

```yaml
id: test-without-assert
language: python
rule:
  all:
    - kind: function_definition
      has:
        field: name
        regex: "^test_"
    - not:
        has:
          any:
            - pattern: assert $EXPR
            - pattern: pytest.raises($$$ARGS)
          stopBy: end
```

## Debugging

```bash
# Show AST structure
ast-grep run --pattern 'def foo(): pass' --lang python --debug-query=ast

# Test a rule file against a file
ast-grep scan --rule my_rule.yml test.py

# Test inline rule
echo "print('hello')" | ast-grep scan --inline-rules "
id: test
language: python
rule:
  pattern: print(\$ARG)
" --stdin

# Show all matches with context
ast-grep scan --rule my_rule.yml . --json | jq '.[] | {file: .filename, line: .range.start.line}'
```
