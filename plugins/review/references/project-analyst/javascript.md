# JavaScript / TypeScript checks

Read this after detecting a JS or TS project (`package.json`, `tsconfig.json`).
These are the things Nigel looks for beyond general JS knowledge.

## Code

- ESLint and Prettier configured and actually passing.
- TypeScript strictness: `strict: true`, ideally `noUncheckedIndexedAccess`;
  `any` and `as` casts used to silence the compiler.
- Floating promises and missing rejection handling.
- `innerHTML` with user input, `eval()`, prototype pollution through object merges.

## Packaging

- `package.json`: `exports`, `types`, `files`, `engines`, `license`, `repository`;
  a lockfile committed.
- Types exported for consumers; JSDoc on the public API of untyped packages.
- Bundle size: tree-shaking not defeated by barrel files or side-effectful
  imports; heavy dependencies loaded dynamically where it matters.
