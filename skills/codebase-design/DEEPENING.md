# Deepening

How to deepen a cluster of shallow modules safely, given its dependencies.
Assumes the vocabulary in `SKILL.md` - module, interface, seam, adapter.

## Dependency categories

Classify a candidate's dependencies before deepening it; the category
decides how the deepened module gets tested across its seam.

1. **In-process** - pure computation, in-memory state, no I/O. Always deepenable: merge the modules, test through the new interface directly, no adapter needed.
2. **Local-substitutable** - dependencies with a local test stand-in (PGLite for Postgres, an in-memory filesystem). Deepenable if the stand-in exists; the seam stays internal, test with the stand-in in the suite, no port at the external interface.
3. **Remote-owned, ports & adapters** - your own services across a network boundary. Define a port at the seam; the deep module owns the logic, the transport is an injected adapter - an in-memory adapter for tests, the real one in production.
4. **True-external, mock** - third-party services you don't control. Inject the dependency as a port; tests supply a mock adapter.

## Seam discipline

- One adapter means a hypothetical seam; two adapters means a real one -
  don't introduce a port unless at least two adapters are justified.
- Internal seams (private to an implementation, used by its own tests)
  don't need to reach the external interface just because tests use them.

## Testing across the seam

- In-process and local-substitutable categories test through the interface
  with the real thing or its stand-in running in the suite.
- Remote-owned and true-external categories test through the port with an
  in-memory or mock adapter; production wiring supplies the real adapter.
- Old unit tests on shallow modules become waste once tests at the deepened
  module's interface exist - delete them, don't layer on top.
- Tests assert on observable outcomes through the interface, not internal
  state; a test that has to change when the implementation changes was
  testing past the interface.
