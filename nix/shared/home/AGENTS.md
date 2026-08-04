# global agent instructions

## Style

- Never use the em dash "—". Write the sentence in a way that does not need a dash. If not possible preference would be a plain dash "-" instead.

## Git

- When writing commit messages, NEVER auto-add your agent name as co-author and keep the commit messages concise, short sentences are easier to digest by a human reviewer.
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated.
- Never commit superpowers docs or design files to git.

## Engineering principles

- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.

## Testing and quality

- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- Hold a high standard for quality: when end-to-end testing a product, be picky about the UI and obsessed with pixel perfection; when you notice lint errors, test failures, or test flakiness, get them fixed.
  This applies even when the issue is not directly related to what you are currently working on.

## Agent behavior

- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.

## Workflow

### Planning the work

Work back and forth with me, starting with your open questions and outline
before writing the plan.

### Atomic, logical changes

- Every set of code modifications that forms a distinct logical unit MUST live
  in its own commit/change.
- Each commit/change MUST be able to stand on its own: the code builds, tests
  pass, and linters pass.
- Do NOT bundle unrelated modifications into a single commit/change.
- Code modification related to feedback and reviews belong in the commit/change
  that originally introduced them, not a separate commit/change.

### Avoid over-editing

IMPORTANT: Try to preserve the original code and the logic of the original code
as much as possible. This is about not rewriting code you were not asked to
touch, it does not override the instruction above to still fix quality issues
you notice along the way.

### Self review

After implementing something, always look back and critically review what you
did with the following in mind:

- Explicitness/simplicity over implicitness/cleverness
- Consistent and systematic approach instead of fragmented and ad-hoc solutions
- YAGNI
- Great DX and UX
- Ease of long-term maintenance
- Follow conventions by the language, ecosystem, open source community
- Brittle or potentially buggy code

If you discover apparent improvement areas, go back and refactor. When unsure,
ask questions.