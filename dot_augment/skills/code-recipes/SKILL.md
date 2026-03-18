---
name: code-recipes
description: Use when you solve a problem with reusable code - capture working examples that agents can fetch and recombine for future problems
---

# Code Recipes

Hoard working code examples so agents can recombine them for future problems.

**Inspired by:** Simon Willison's "Hoard things you know how to do" pattern -
you only need to figure out a trick once if it's documented with working code.

## When to Use

- Figured out how to do something non-trivial
- Used a library in a specific way that took effort to discover
- Combined two technologies in a working solution
- Solved a problem you'll likely face again
- Got an agent to successfully solve a tricky integration

## Capture Process

1. **Verify it works** - Must be tested, working code
2. **Extract minimal example** - Strip to essentials, no project-specific
   details
3. **Document the "what" and "why"** - Not just code, but context
4. **Save to Basic Memory** - `knowledge/recipes/{technology}/{topic}.md`

## Recipe Structure

```markdown
---
title: {Descriptive Title}
type: recipe
tags:
  - recipe
  - {technology}
  - {category}
source: code-analysis
confidence: high
observed: {YYYY-MM-DD}
---

# {Title}

## Problem

What problem does this solve? What were you trying to accomplish?

## Solution

\`\`\`{language}
# Minimal working code
# Include imports
# Include setup if needed
\`\`\`

## Key Points

- Why this approach works
- Gotchas to watch for
- Dependencies required
- Version constraints if any

## Usage

How to adapt this recipe for similar problems:
1. Copy the core pattern
2. Modify X for your use case
3. Ensure Y is configured

## Observations

- [pattern] Reusable approach for {X} #recipe
- [verified] Tested and working as of {date}

## Relations

- relates-to \[[related-technology]]
- enables \[[what-this-makes-possible]]
```

## Example Recipes

### Browser OCR with Tesseract.js

```markdown
## Problem
Need to OCR images directly in the browser without server-side processing.

## Solution
\`\`\`javascript
const worker = await Tesseract.createWorker();
await worker.loadLanguage('eng');
await worker.initialize('eng');
const { data: { text } } = await worker.recognize(imageUrl);
await worker.terminate();
\`\`\`

## Key Points
- Uses WebAssembly, works in any modern browser
- Load from CDN: https://unpkg.com/tesseract.js@v2.1.0/dist/tesseract.min.js
- Worker is stateful - initialize once, recognize many
```

### PDF to Images with PDF.js

```markdown
## Problem
Render PDF pages as images in browser for display or processing.

## Solution
\`\`\`javascript
pdfjsLib.GlobalWorkerOptions.workerSrc = 'path/to/pdf.worker.min.js';
const pdf = await pdfjsLib.getDocument(url).promise;
const page = await pdf.getPage(1);
const viewport = page.getViewport({ scale: 1.5 });
const canvas = document.createElement('canvas');
canvas.width = viewport.width;
canvas.height = viewport.height;
await page.render({ canvasContext: canvas.getContext('2d'), viewport }).promise;
const imageUrl = canvas.toDataURL('image/jpeg', 0.8);
\`\`\`
```

## Recipe Organization

| Category | Directory | Examples |
|----------|-----------|----------|
| Web/Browser | `knowledge/recipes/web/` | WebAssembly, Canvas, Workers |
| Python | `knowledge/recipes/python/` | Async patterns, CLI tools |
| Database | `knowledge/recipes/database/` | SQLite tricks, PostgreSQL |
| Integration | `knowledge/recipes/integration/` | API patterns, auth flows |
| DevOps | `knowledge/recipes/devops/` | Docker, K8s, CI/CD |

## Combining Recipes

The power is in recombination.
Tell agents:

```text
Combine the PDF-to-images recipe with the Tesseract OCR recipe
to build a tool that extracts text from scanned PDF documents.
```

Agents with access to your recipes can fetch and synthesize them.

## Best Practices

1. **Minimal but complete** - Include imports, don't assume context
2. **Actually tested** - Never save untested code as a recipe
3. **Version-aware** - Note library versions that work
4. **Link freely** - Connect related recipes
5. **Update when broken** - Recipes with outdated deps lose value

## MCP Tools

```python
# Save a new recipe
write_note_basic - memory(
    title="FastAPI Async HTTP Client Pattern",
    content="[recipe content]",
    directory="knowledge/recipes/python",
    tags=["recipe", "python", "fastapi", "async"],
)

# Find existing recipes
search_notes_basic - memory(query="recipe browser canvas", tags=["recipe"])
```
