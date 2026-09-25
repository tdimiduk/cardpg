---
title: "Brief: KeywordMod & Wikilink Standardization"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Brief: KeywordMod & Wikilink Standardization

## Objective

Update `tools/design_utils/keyword_mod.py` to support wikilink double-bracket syntax (`[[Keyword]]`) for game glossary terms, and execute a repository-wide normalization pass across design documentation.

---

## Background & Rationale

Historically, keywords were tagged using inline backticks (e.g., `` `Strength` `` or `` `Defense` ``). This caused two main issues:

1. **Semantic Collision:** Inline backticks in Markdown represent code literals/monospaced fonts, making rules read like API docs.
2. **Grammatical Glitches:** Suffixes and plurals created awkward formatting (e.g., `` `Color`s ``).

Adopting double brackets (`[[Strength]]`, `[[Crisis Time]]`) cleanly marks terms for the documentation and publishing pipeline (to automatically resolve links to `design/rules/keyword-glossary.md`) without colliding with Markdown code syntax.

---

## Technical Tasks for `tools/design_utils/keyword_mod.py`

1. **Update Fencing Function:**

   ```python
   def fencedKeyword(keyword: str) -> str:
       return f"[[{keyword}]]"
   ```

2. **Improve Normalization Regex:**
   Ensure `mutateFileNormalizeKeyword` matches legacy backticked instances (`` `Keyword` ``), bold-wrapped keywords (`**Keyword**`), and unbracketed plain keywords while avoiding duplicate brackets:

   ```python
   # Match existing backticks or single/double brackets around keyword
   pattern = rf"(?<!\[)\[*`?{re.escape(keyword)}`?\]*(?!\])"
   ```

3. **Plural & Alias Handling:**
   Support mapping inflections (e.g., `Colors` -> `[[Colors]]` or `[[Color]]s`) based on an aliases table defined in `design/rules/keyword-glossary.md`.

4. **Integration with `keyword-glossary.md`:**
   Add a mode to automatically extract all defined keywords from `design/rules/keyword-glossary.md` and run normalization across the repo without having to invoke the script keyword-by-keyword.

---

## Target Scope

- `design/rules/*.md`
- `design/rules/modules/*.md`
- `design/philosophy/*.md`
- Exclude `code/`, `.git/`, and external research archives as already handled by `ignorePath`.
