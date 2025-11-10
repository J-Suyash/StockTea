# Repository Guidelines

## Project Structure & Module Organization
- `contents/ui`: QML views and components (e.g., `main.qml`, `PortfolioView.qml`).
- `contents/code`: Logic modules in JavaScript and Python (e.g., `stock-data-loader.js`, `stock_processor.py`).
- `contents/config`: Configuration QML/XML and related helpers.
- `metadata.json`: Package metadata. `README.md`: usage and overview. Icons like `piggy-bank-icon.svg` may be at root or under `contents/ui`.

## Build, Test, and Development Commands
- `./install.sh`: Installs/updates the package locally.
- `qmlscene contents/ui/main.qml`: Preview the main UI during development.
- Use console logging in JS and `print()` in Python for local debugging of loaders and models.

## Coding Style & Naming Conventions
- Indentation: QML/JS 2 spaces; Python 4 spaces.
- QML components: PascalCase filenames (e.g., `PositionItem.qml`); the entrypoint remains `main.qml`. Keep UI logic in QML; business logic in `contents/code`.
- JavaScript modules: kebab-case filenames (e.g., `watchlist-manager.js`), prefer `const/let`, avoid `var`; write small, pure functions when possible.
- Python: snake_case filenames/functions (e.g., `stock_processor.py`). Add type hints where helpful.

## Testing Guidelines
- No formal test suite yet; use `qmlscene` for manual UI checks and `contents/code/fallback-data-loader.js` for deterministic data.
- When introducing tests:
  - Python: use `pytest`; mirror structure under `tests/python/`.
  - JS: use a lightweight runner (e.g., `vitest`); place tests under `tests/js/`.
  - Target data loaders, portfolio models, utils; aim for basic coverage.

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject with scoped prefix where relevant (e.g., `ui:`, `code:`, `config:`). Include rationale in the body if non-trivial.
- PRs: clear description, linked issues, screenshots/GIFs for UI changes, and a short test plan (steps to reproduce, sample data used).

## Security & Configuration Tips
- Do not commit secrets or API tokens. Keep credentials in environment or ignored local files.
- Prefer `fallback-data-loader` for offline/dev; avoid live API calls in CI or automated checks.
