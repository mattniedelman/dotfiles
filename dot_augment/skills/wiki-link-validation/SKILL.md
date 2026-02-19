---
name: wiki-link-validation
description: Use when creating or editing Basic Memory notes with wiki links - validates links against Obsidian live broken links report to prevent creating unresolvable [[wiki links]]
---

# Wiki Link Validation

This skill prevents creating broken wiki links in Basic Memory / Obsidian by
checking against a live broken links report before writing notes.

## When to Use

Use this skill when:

- Creating new Basic Memory notes with \`[[wiki links]]\`
- Editing notes that add new wiki links
- Writing notes that reference people, teams, projects, or concepts
- Before committing notes to ensure link integrity

## Background

Obsidian wiki link resolution is internal state not directly accessible via
API. However, we maintain a live broken links report that updates automatically
when files change in the vault.

**Key file:** \`working/broken-links-live.md\`

This file contains a Dataview Serializer query that shows all unresolved wiki
links in the vault, auto-updated when Obsidian detects file changes.

## Workflow

### 1. Read the Broken Links Report

Before creating wiki links, check current broken links:

\`\`\`python
# Read the live broken links report
obsidian_read_note_obsidian(
    filePath="working/broken-links-live.md",
    format="markdown"
)
\`\`\`

### 2. Parse the Results

The file contains a serialized table with format:

\`\`\`markdown
| Source File | Broken Links |
| - | - |
| [[some-note]] | LinkA, LinkB, LinkC |
\`\`\`

Extract broken link targets to know which links currently don not resolve.

### 3. Before Creating Wiki Links

When about to write a note with wiki links:

1. **Check if target exists** - Does \`[[Target Name]]\` appear in broken links?
2. **If target does not exist** - Decide whether to:
   - Create the target page first (preferred for important concepts)
   - Use the link anyway (acceptable for future-proofing)
   - Use different wording that links to existing content

### 4. Link Resolution Rules

Obsidian resolves wiki links by **filename match**:

- \`[[Matt Niedelman]]\` looks for file named \`Matt Niedelman.md\`
- Aliases in frontmatter are unreliable for resolution
- **Best practice:** Use exact filename (with spaces) for frequently-linked notes

### 5. Creating Missing Pages

If you need to create a page for a broken link:

\`\`\`python
# Search for where the broken link appears
obsidian_global_search_obsidian(
    query="[[Missing Page Name]]"
)

# Create the missing page
obsidian_update_note_obsidian(
    targetType="filePath",
    targetIdentifier="appropriate/folder/Missing Page Name.md",
    content="---\ntitle: Missing Page Name\n---\n\n# Missing Page Name\n\nTODO: Add content\n",
    modificationType="wholeFile",
    wholeFileMode="overwrite",
    createIfNeeded=True,
    overwriteIfExists=False
)
\`\`\`

## Quick Reference

| Scenario | Action |
|----------|--------|
| Writing note with \`[[Person Name]]\` | Check if person file exists |
| Linking to \`[[Concept]]\` | Verify concept page exists or create it |
| Creating reference to \`[[Project]]\` | Ensure project note exists |
| Found in broken links report | Create target page or fix link text |

## Common Broken Link Patterns

From analysis of the vault, common categories include:

- **Technology names** - \`[[Git]]\`, \`[[Python]]\`, \`[[AI]]\`
- **Generic concepts** - \`[[testing]]\`, \`[[design-patterns]]\`
- **Team references** - \`[[Some Team]]\`
- **Date-based links** - Sometimes from daily notes

## Data Freshness

The broken links report updates:

- **Automatically** - When you edit any note in Obsidian (~10s debounce)
- **Manually** - Via "Scan and serialize all Dataview queries" command
- **NOT** when Augment edits via MCP (Obsidian does not detect external changes)

After creating pages via MCP, the report will not immediately reflect the fix.
The report updates next time you interact with Obsidian.

## Pre-flight Check Example

Before writing a note with multiple wiki links:

\`\`\`python
# 1. Read current broken links
broken_links_content = obsidian_read_note_obsidian(
    filePath="working/broken-links-live.md",
    format="markdown"
)

# 2. Extract broken link targets from the table
# Look for patterns like: Git, Python, [[Some Note]]

# 3. Check your intended links against known broken ones
# my_links = ["[[Matt Niedelman]]", "[[AI Engineering Team]]", "[[New Concept]]"]

# 4. For any that appear broken, either:
#    - Create the target page first
#    - Adjust the link to match an existing page
#    - Proceed with awareness it will be a broken link
\`\`\`

## Best Practices

1. **Check before bulk writes** - Read broken links before writing multiple notes
2. **Create stubs for important links** - Better to have a TODO page than broken link
3. **Use exact filenames** - Match the exact filename including spaces
4. **Prefer existing pages** - Search for existing pages before creating new ones
5. **Periodic cleanup** - Review broken links report regularly to fix accumulation
