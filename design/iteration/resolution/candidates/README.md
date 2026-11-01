---
title: "Candidate Resolution Mechanics Catalog"
doc_type: meta
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Candidate Resolution Mechanics Catalog

This directory houses proposed candidate resolution mechanics, alternative architectures, and active mechanical exploration suites for **caRdPG**.

Before advancing any candidate to proposal status or testing it in play traces, evaluate it against the authoritative [constraints.md](../constraints.md) and audit it against [pitfalls.md](../pitfalls.md). Check if is mechanically equivalent to an idea that has already been evaluated and rejected [discarded-ideas.md](../discarded-ideas.md).

---

## 1. Active Candidate Catalog

| Candidate                                                                                 |         Status          | Core Mechanism                                                                                                                      | Key Strengths                                                                                                 | Open Questions / Known Risks                                                   |
| :---------------------------------------------------------------------------------------- | :---------------------: | :---------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------- |
| **[Consequence Pool & Tag Escalation Engine](consequence-pool-tag-escalation/README.md)** | **Full Proposal Suite** | Layered Pool Fill ($1\text{ Impact} = 1\text{ Card}$) + _"I Cut, You Choose"_ consequence drafting market + $I < N$ soak threshold. | High defender agency, clean non-HP harm model, domain decoupling via tags, symmetrical minion design ($N=1$). | Multi-deck table footprint (4 decks) and heavy card draws on penetrating hits. |
