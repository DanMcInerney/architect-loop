<!-- Adapted from mattpocock/skills (MIT). -->

# Good and Bad Tests

## Good tests

**Through the seam**: test real behavior, not mocks of internal parts.

```typescript
// GOOD: tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior a caller of the seam cares about
- Uses the seam only, never internals
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad tests

**Implementation-coupled**: tied to internal structure instead of the seam.

```typescript
// BAD: tests implementation details
test("checkout calls paymentModule.process", async () => {
  const mockPayment = jest.mock(paymentModule);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW, not WHAT
- Verifying through a side channel instead of the seam

```typescript
// BAD: bypasses the seam to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: verifies through the seam
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**Tautological tests**: the expected value restates the implementation, so
the test passes by construction.

```typescript
// BAD: expected value is recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

## Factory seams

A ship job's seams are the ones named in its issue body and spec — not
whatever the builder finds convenient to reach into. If the named seam is a
function, test that function's return value; if it's a CLI exit code, test
the exit code and stdout/stderr the check itself will read. Never write a
test against a frozen check file — those are read-only grading, not fixtures.
