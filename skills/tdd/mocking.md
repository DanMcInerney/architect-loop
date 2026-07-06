<!-- Adapted from mattpocock/skills (MIT). -->

# When to Mock

Mock at **system boundaries** only:

- External third-party systems (payment, email)
- Databases (sometimes - prefer a real test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own modules
- Internal collaborators
- Anything you control

## Designing for mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer one function per external operation over a generic fetcher**

```typescript
// GOOD: each function is independently mockable
const external = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch("/orders", { method: "POST", body: data }),
};

// BAD: mocking requires conditional logic inside the mock
const external = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

One seam per external operation means: each mock returns one specific shape,
no conditional logic in test setup, and it's obvious which external
operations a given test exercises.
