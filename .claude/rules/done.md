# Definition of Done

Work is done when it has been independently verified — not when you believe
it works, but when you can prove it works. These rules define what "done"
means for this project.

## Rules

- **Verified, not assumed.** Every claim of completion must be backed by
  evidence: a passing test, a successful Simulator build, or confirmed
  output. If you can't show it working, it isn't done.
- **Tests prove behavior changed.** New behavior needs a test that fails
  without the change and passes with it. A test that passes either way
  proves nothing.
- **The build is clean.** `xcodebuild build` succeeds with zero errors and
  zero warnings on the `PokeJournal Capture` scheme.
- **The test suite passes.** `script/test` exits 0. No skipped tests unless
  documented with a reason.
- **Error paths are exercised.** Happy-path-only verification is incomplete.
  Done means you've confirmed what happens when inputs are wrong or state
  is unexpected.
- **Export format is preserved.** Changes to models or export logic must not
  break the Markdown export format. Verify with ExportService tests.
- **German strings are correct.** All user-facing text is in German. New UI
  strings must use the correct language — no English placeholders left behind.
- **Smooth beats fast.** Rushing to "done" creates rework. Small, verified
  increments compound into reliable progress. Big leaps create big risks.
- **Clean working tree.** No uncommitted debug code, no TODO hacks, no
  commented-out blocks left behind.
- **Documentation matches reality.** If behavior changed, CLAUDE.md and any
  comments that reference it are updated.
