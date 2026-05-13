# Skill Authoring Guide

Guide for writing skills that a harness generates.
Supplements SKILL.md Phase 4.

---

## Table of Contents

1. [Description Writing](#1-description-writing)
2. [Body Writing Style](#2-body-writing-style)
3. [Output Format Definition](#3-output-format-definition)
4. [Progressive Disclosure](#4-progressive-disclosure)
5. [Script Bundling](#5-script-bundling)
6. [What Not to Include](#6-what-not-to-include)

---

## 1. Description Writing

The description is the sole trigger mechanism.
Claude sees only name + description from the `available_skills` list when
deciding whether to activate.

### Trigger Behavior

Claude tends not to invoke skills for tasks it can handle with built-in tools.
Simple requests may not trigger even with a well-written description.
Complex, multi-step, specialized tasks trigger more reliably.

### Writing Principles

1. List what the skill does AND the specific trigger situations
2. Distinguish boundary cases where a similar-but-different skill applies
3. Write aggressively -- compensate for Claude's conservative trigger bias

### Examples

BAD:
`"Data processing skill"`

GOOD:
`"PDF file reading, text/table extraction, merge, split, rotate, watermark,
encrypt/decrypt, OCR -- all PDF operations.
If the user mentions .pdf or requests PDF output, use this skill.
Particularly useful when conversion, editing, or analysis is needed beyond
simple reading."`

BAD:
`"Handles spreadsheet operations"`

GOOD:
`"Excel/CSV/TSV column addition, formula computation, formatting, charting, data
cleaning -- all spreadsheet operations.
If the user mentions a spreadsheet file, even casually ('the xlsx in my
downloads'), use this skill."`

---

## 2. Body Writing Style

### Why-First Principle

Claude generalizes from understanding.
Explaining reasoning is more effective than issuing directives, especially for
edge cases.

BAD:

```text
ALWAYS use pdfplumber for table extraction. NEVER use PyPDF2 for tables.
```

GOOD:

```text
Use pdfplumber for table extraction. PyPDF2 specializes in text extraction
and does not preserve row/column structure. pdfplumber recognizes cell
boundaries and returns structured data.
```

### Generalization Principle

When feedback reveals a problem, fix at the principle level, not the example
level.
Narrow fixes overfit.

BAD:
`If a column named "Q4 Revenue" exists, convert it to numeric.`

GOOD:
`If a column name contains revenue, amount, quantity, or other numeric-implying
keywords, convert it to numeric type.
On conversion failure, preserve the original value.`

### Voice and Economy

- Imperative voice:
  "Extract the data" not "The data should be extracted"
- Every sentence must justify its token cost:
  - Claude already knows this?
    Delete.
  - Without this line, Claude makes mistakes?
    Keep.
  - One example replaces a paragraph of explanation?
    Use the example.

---

## 3. Output Format Definition

When output structure matters, define it concisely with a template:

```markdown
## Report Structure

Follow this template exactly:

# [Title]
## Summary
## Key Findings
## Recommendations
```

Include one concrete example if the format has nuance.
Lengthy format specs belong in `references/`.

---

## 4. Progressive Disclosure

### Pattern: Domain-Specific Split

```text
bigquery-skill/
  skill.md (overview + domain selection guide)
  references/
    finance.md (revenue, billing metrics)
    sales.md (opportunity, pipeline)
    product.md (API usage, features)
```

Load only the relevant domain file based on the user's query.

### Pattern: Conditional Detail

```markdown
## Document Generation

Use docx-js for new documents. See [DOCX-JS.md](references/docx-js.md).

## Document Editing

Simple edits: modify XML directly.
**If tracked changes are needed**: see [REDLINING.md](references/redlining.md).
```

### Size Management

- When skill.md approaches 500 lines, move detail to references/ and leave a
  pointer ("read this file when X")
- Reference files over 300 lines get a table of contents at the top
- Domain/framework variants go in separate reference files so only the relevant
  one loads

---

## 5. Script Bundling

Watch agent transcripts during testing.
If a pattern appears, bundle it:

| Signal | Action |
| ------ | ------ |
| All test runs produce the same helper script | Bundle in `scripts/` |
| Every run installs the same dependencies | Document install step in skill |
| Same multi-step workaround applied every time | Write as standard procedure |
| Same error followed by same fix every time | Document as known issue + fix |

Bundled scripts must pass execution tests before inclusion.

---

## 6. What Not to Include

- README, CHANGELOG, installation guides (skills are agent instructions, not
  user documentation)
- Meta-information about the creation process (test results, iteration history)
- General knowledge Claude already has
- Subjective language ("excellent", "powerful", "elegant")
