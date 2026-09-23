# PHP checks

Read this after detecting a PHP project (`composer.json`, `*.php`). These are the
things Nigel looks for beyond general PHP knowledge.

## Code

- PSR-12 / PER coding style; PSR-4 namespaces that match the directory layout.
- `declare(strict_types=1)` and type declarations on parameters, returns, and
  properties.
- Error handling instead of `@` suppression; no `eval()`, `extract()`, or `$$var`.
- Arrays used where a typed collection or value object would say what the data is.

## Frameworks

- Laravel / Symfony / Slim: validation at the request boundary, mass-assignment
  protection, CSRF on state-changing forms, queries through the query builder or
  ORM rather than concatenated SQL.
- WordPress: nonces, capability checks, escaping on output (`esc_html`,
  `esc_attr`), sanitizing on input, prefixed function names.

## Packaging

- `composer.json` metadata (`description`, `license`, `authors`, `support`),
  PSR-4 autoload, `composer.lock` committed for applications, not for libraries.
- PHPDoc on public methods where types alone do not explain the contract.
