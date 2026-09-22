# Contributing to Easy Image

Thank you for your interest in contributing to `easy_image`!

## Code of Conduct

Please be polite, respectful, and collaborative.

## Development Setup

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run tests:
   ```bash
   flutter test
   ```
4. Verify code formatting and linting:
   ```bash
   dart format --output=none --set-exit-if-changed .
   flutter analyze --fatal-infos
   ```

## Pull Request Guidelines

- All tests must pass.
- Code should be clean, properly typed, and documented.
- Add unit or widget tests covering any new features or bug fixes.
- Update `CHANGELOG.md` with a summary of your changes under the unreleased or upcoming release section.
- Avoid breaking existing public APIs without deprecation notices.
