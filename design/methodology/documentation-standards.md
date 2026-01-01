# Documentation Standards

## Document Purpose

This document is the official style guide for all markdown-based design documents in this project. Its purpose is to ensure that our work is clear, consistent, and structurally sound. Adhering to these standards makes our documents easier to read, maintain, and parse for both human designers and our AI partners.

---

## The Document Standard

All new and refactored documents must adhere to the following four principles of structure and formatting.

### 1. Single H1 Title

Every document must begin with a single, clear Level 1 heading (`#`) that serves as its official, human-readable title. There should only be one H1 heading in any given file.

### 2. "Intro-First" Pattern

Immediately following the H1 title, there must be a brief, reader-facing introductory section. This text should orient the reader to the document's contents, its purpose, and its context within the broader project.

### 3. Hierarchical Headings

All subsequent sections within the document must use Level 2 (`##`) headings for primary sections, with sub-sections using `###`, and so on. This creates a clean, consistent, and machine-parsable document outline.

### 4. Authoring Notes

Any notes, style guides, or instructions intended specifically for the author or editor of a document should not be part of the main text. Instead, they must be placed in a non-rendering markdown comment block (``) at the top of the file, immediately after the H1 title and introduction. This keeps internal guidance attached to the relevant document without cluttering the output for the intended audience.

### Example of a Well-Formed Document

```markdown
# Title of the Document

This is the introductory paragraph. It explains what the document is about and why it is important, orienting the reader before they dive into the details.

---

## First Primary Section

Content for the first section goes here.

### A Subsection

More detailed content goes here.

## Second Primary Section

Content for the second section goes here.
```
