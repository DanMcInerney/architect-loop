<!-- Adapted from mattpocock/skills (MIT). -->

# When to Mock

Mock at **system boundaries** only — the edge where your codebase meets
something outside it:

- External third-party systems (payment, email)
- Databases (sometimes — prefer a real test database)
- Time and randomness
- The file system (sometimes)

Don't mock:

- Your own modules
- Internal collaborators
- Anything the codebase itself controls

## Designing for mockability

At a system boundary, shape the seam so it's easy to mock.

**1. Inject the dependency**

Pass the external dependency in rather than constructing it inside the module:

```typescript
// Easy to mock: the dependency arrives through the seam
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock: the module builds its own dependency internally
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer one function per external operation over a generic fetcher**

```typescript
// GOOD: each seam is independently mockable
const external = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch("/orders", { method: "POST", body: data }),
};

// BAD: mocking this seam requires conditional logic inside the mock
const external = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

One seam per external operation means: each mock returns one specific shape,
no conditional logic in test setup, and it's obvious which external
operations a given test exercises.
