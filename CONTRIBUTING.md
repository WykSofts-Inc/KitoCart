# Contributing to KitoCart

Thanks for considering a contribution — Kito is open source and welcomes
issues and pull requests from anyone.

## Governance

- **Anyone can open an issue or a pull request.**
- **Only the maintainer ([wyksoftsinc.com](https://wyksoftsinc.com), repo
  owner Wycliff) merges pull requests.** This applies even to contributors
  who are granted write access for other reasons (e.g. triage) — merging is
  reserved for the maintainer after review, not delegated.
- Every PR is verified before merge: it must build, its tests must pass, and
  it must follow the engineering standards linked below.

## Before you start

**Open an issue first** for anything beyond a trivial fix. Trivial fixes can
go straight to a PR.

## Workflow

1. Fork the repo.
2. Create a branch off `main`.
3. Follow [KitoCore's engineering standards](https://github.com/WykSofts-Inc/KitoCore/blob/main/docs/ENGINEERING_STANDARDS.md).
4. Add or update tests. Run `swift test` locally and make sure it's green.
5. Update the README if you changed or added public API.
6. Open a pull request against `main`. Describe what changed and why.
7. Wait for review — please don't merge your own PR even if your fork has
   that permission.

## Code review checklist

- [ ] Builds cleanly (`swift build`)
- [ ] Tests pass (`swift test`), and new behavior has new tests
- [ ] No `fatalError()`, `try!`, or unexplained force-unwrap in public code
- [ ] No hardcoded color/spacing/font/radius — reads from the theme
- [ ] Public API changes are documented in the README with a sample
- [ ] A platform-gated feature ships its fallback branch in the same PR

## Code of conduct

Be respectful. Disagreement about a technical approach is fine and expected;
personal attacks, harassment, or bad-faith arguing are not.

## License

By contributing, you agree your contribution is licensed under this repo's
[MIT License](LICENSE).
