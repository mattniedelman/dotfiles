---
description: Add a skill from a URL (GitHub repo, gist, or raw markdown)
argument-hint: <url> [skill-name]
---

Add a new skill to my Augment configuration from the provided URL.

**URL**: $ARGUMENTS

## Instructions

1. **Fetch the content** from the provided URL
   - If it's a GitHub repo URL, look for `SKILL.md` in the root or a skills subdirectory
   - If it's a raw file URL or gist, fetch the content directly
   - If it's a GitHub directory, look for `SKILL.md` inside it

2. **Validate the skill**:
   - Must have valid YAML frontmatter with `name` and `description`
   - Name must be 1-64 chars, lowercase alphanumeric and hyphens only
   - Name must not start/end with hyphen or have consecutive hyphens

3. **Create the skill directory** at `~/.augment/skills/<skill-name>/`
   - Use the name from frontmatter, or the optional second argument if provided
   - If directory exists, ask before overwriting

4. **Save the SKILL.md file** to the new directory

5. **Confirm success** and show the skill name and description

## Example URLs

- `https://github.com/user/repo` - Look for SKILL.md in repo
- `https://github.com/user/repo/tree/main/skills/my-skill` - Specific skill directory
- `https://raw.githubusercontent.com/user/repo/main/SKILL.md` - Raw file
- `https://gist.github.com/user/abc123` - Gist containing SKILL.md

