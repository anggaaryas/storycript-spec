---
name: storyscript-feature-spec-guard
description: 'Use when adding or revising any StoryScript language feature. Enforces unambiguous feature scope, mandatory compile-time validation rules, standard diagnostic code coverage, and a concrete example .StoryScript file.'
argument-hint: 'Feature name plus intended behavior and constraints'
user-invocable: true
disable-model-invocation: false
---

# StoryScript Feature Spec Guard

## Outcome
Produce a complete feature specification update where every feature change includes:
- A zero-ambiguity scope contract.
- Compile-time validation rules.
- Standard diagnostic code mapping.
- At least one executable example .StoryScript file.

## Use When
- Adding a new language feature to StoryScript.
- Extending behavior of an existing StoryScript construct.
- Changing parser or validator behavior that affects language semantics.
- Reviewing feature proposals before implementation.

## Required Inputs
- Feature name.
- Feature intent (what user problem it solves).
- Current files to update (at minimum: PLAN.md and one example file path).

If any required input is missing, stop and ask for it before drafting changes.

## Procedure
1. Define scope contract first.
2. Draft language semantics and syntax.
3. Add compile-time validation rules.
4. Map each rule to standard diagnostic codes.
5. Add or update a representative example .StoryScript file.
6. Run completion checks and publish the feature bundle.

## Step 1: Define Scope Contract (No Ambiguity)
Write a scope block with all fields below. Do not continue until all fields are explicit.

```markdown
### Feature Scope Contract
- In Scope:
- Out of Scope:
- Affected Phases: INIT | PREP | STORY | Runtime
- New Syntax (exact grammar/signature):
- Type Rules:
- Control Flow Impact:
- Backward Compatibility:
- Migration Notes (if any):
```

Scope rules:
- "In Scope" and "Out of Scope" must each contain at least 2 concrete bullets.
- "New Syntax" must include exact token-level shape, not paraphrases.
- "Type Rules" must state accepted types, rejected types, and coercion rules.
- "Control Flow Impact" must state whether termination analysis changes.

## Step 2: Draft Semantics and Syntax
Update the feature section in [PLAN.md](../../../PLAN.md) with:
- Syntax form.
- Execution semantics.
- Type semantics.
- Phase restrictions (where feature is allowed/forbidden).

Decision points:
- If the feature changes parser shape, include grammar-level examples.
- If the feature changes runtime only, still define compile-time rejection boundaries.

## Step 3: Add Compile-Time Validation Rules (Mandatory)
For every feature, add explicit validation bullets under compile-time rules in [PLAN.md](../../../PLAN.md).

Validation rule requirements:
- State trigger condition in deterministic language.
- State compile-time failure condition.
- Avoid vague words like "invalid usage" without concrete criteria.

Validation format:
- "Any <condition> must fail compile-time validation with <diagnostic code>."

## Step 4: Standard Diagnostic Code Mapping (Mandatory)
Map each new or affected validation rule to a stable diagnostic code.

Standardization policy:
- Reuse existing codes when semantics are unchanged.
- Add new code only when behavior cannot be represented by an existing code.
- New compile-time codes must use E_* prefix.
- New warning codes must use W_* prefix.
- Runtime-only failures use R_* and must not replace compile-time failures.

Update both locations when introducing a new code:
- [PLAN.md](../../../PLAN.md) diagnostic table.
- [parser/rust/src/diagnostic.rs](../../../parser/rust/src/diagnostic.rs) DiagnosticCode enum and Display mapping.

Required mapping table in the feature write-up:

| Rule ID | Validation Condition | Diagnostic Code | Rationale |
|---|---|---|---|
| F001 | ... | E_... | ... |

## Step 5: Add Example .StoryScript File (Mandatory)
Create or update at least one example file under [example](../../../example/) that demonstrates:
- Valid usage path.
- Invalid usage notes (as comments or companion negative sample).
- Interaction with existing language constructs when relevant.

Example naming convention:
- `feature_<short_name>.StoryScript` for new features.
- Extend an existing file only when it is already the canonical showcase for that area.

Minimum example coverage:
- 1 happy path scene.
- 1 boundary condition.
- 1 failure case description tied to a diagnostic code.

## Step 6: Completion Checks (Definition of Done)
A feature update is complete only if all checks pass:
- Scope contract is fully filled with no TBD fields.
- PLAN semantics are explicit and phase-bounded.
- Compile-time validation rules exist for all new constraints.
- Diagnostic mapping table exists and all codes resolve to standard naming.
- Example .StoryScript file exists in [example](../../../example/) and matches semantics.
- If new code added: both PLAN and [parser/rust/src/diagnostic.rs](../../../parser/rust/src/diagnostic.rs) are updated consistently.

## Branching Logic
- If a feature introduces syntax but no new failure mode: reuse existing diagnostic codes and justify reuse.
- If a feature introduces a new failure mode: add one or more new codes and document each trigger.
- If scope cannot be made explicit in one pass: stop and request missing constraints instead of guessing.

## Anti-Ambiguity Rules
- Never use "etc." in scope or validation text.
- Never merge compile-time and runtime errors in one rule.
- Never omit affected phase constraints.
- Never ship feature text without a concrete example file.