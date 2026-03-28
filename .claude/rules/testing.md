# Testing Rules

Tests are a design tool, not a verification afterthought. Write them early,
learn from the friction, and let them shape your code.

## Framework

- Use **Swift Testing** (`import Testing`, `@Test`, `#expect`) for all new tests.
- Do not use XCTest for new unit tests — only UI tests use XCTest/XCUITest.
- Test files live in `PokeJournal CaptureTests/` (unit) and
  `PokeJournal CaptureUITests/` (UI/integration).

## Guidelines

- **Write the test before the code.** If you can't write the test first, you
  likely don't understand the requirement well enough yet.
- **One behavior per test.** When a test fails, you should immediately know
  what broke without reading the implementation.
- **Tests must be fast, isolated, and deterministic.** Flaky tests erode trust.
  Slow tests don't get run. Either outcome degrades the value of the suite.
- **New behavior requires a new test** that would fail if the code were reverted.
- **Bug fixes require a regression test** that reproduces the original failure
  before you write the fix.
- **Test behavior, not implementation.** Tests should survive a refactor. If
  renaming a private method breaks a test, the test is coupled to the wrong
  thing.
- **Delete tests that don't earn their keep.** Redundant, brittle, or
  chronically slow tests cost attention without providing confidence.
- **Keep tests readable.** Arrange, Act, Assert — with minimal ceremony. A
  good test reads like a specification. If you need extensive setup, extract
  it or reconsider the design.
- **Don't mock what you don't own.** Wrap third-party dependencies behind your
  own interface, then mock that. Tests shouldn't break when a library ships a
  patch.

## SwiftData Testing

- Use an in-memory `ModelConfiguration` for test `ModelContainer`s to avoid
  polluting real data and to keep tests isolated.
- Each test should create its own container — never share mutable state across
  tests.

## What Cannot Be Unit-Tested

- **SwiftUI views** — verify layout and interaction via UI tests or manual
  Simulator runs, not unit tests.
- **Speech recognition / microphone** — requires device hardware. Document
  expected behavior; test the logic around it, not the framework call.
- **SwiftData persistence edge cases** — some behaviors only surface on real
  stores. Cover what you can with in-memory containers; note known gaps.
