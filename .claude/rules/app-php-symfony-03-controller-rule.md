---
paths:
  - "app/src/Controller/**/*.php"
---

# Controller Rule

@see https://symfony.com/doc/current/controller.html

## Core Principles

- Every controller extends `AbstractController`.
- A controller is **glue code only** — it must not contain business logic.
- Aim for 10–15 lines per action method; extract anything larger into a Service.
- Mark controller classes `final` — they are not designed for extension.

## Routing

- Define routes only with PHP Attributes (`#[Route(...)]`).
- Never use YAML or XML route files.
- Route names follow the `{domain}_{subdomain}_{action}` snake_case pattern.
- Explicitly restrict the HTTP method on every action (`methods: ['GET']`, `methods: ['POST']`, etc.).

```php
#[Route('/post/{id}', name: 'post_show', methods: ['GET'])]
public function show(Post $post): Response
{
    return $this->render('post/show.html.twig', ['post' => $post]);
}
```

## Route Parameter Validation

- Add regex constraints with the `requirements` option (required for security).
- Invalid parameters automatically return a 404 before entering the controller.

```php
#[Route('/post/{id}', name: 'post_show', requirements: ['id' => '\d+'])]
// Backed Enum parameters are also automatically converted
#[Route('/status/{status}', name: 'status_show')]
public function show(PostStatus $status): Response {}
```

@see https://symfony.com/doc/current/routing.html#parameters-validation

## Route Grouping (Controller-Level Attribute)

- Apply `#[Route('/admin')]` to the controller class itself to prefix every action.
- Use `name: 'admin_'` on the class to consistently prefix every route name.

```php
#[Route('/admin', name: 'admin_')]
class AdminController extends AbstractController
{
    #[Route('/dashboard', name: 'dashboard')] // → 'admin_dashboard'
    public function dashboard(): Response {}
}
```

## Request Access

- Type-hint `Request $request` on the action method (the preferred approach).
- Use `RequestStack` only inside services, never in a controller.
- `$request->query->get()` — GET parameters (always validate before use).
- `$request->request->get()` — POST parameters (prefer using a Form).

## Response Creation

- `$this->render()` — render a Twig template.
- `$this->json()` — return a JSON response (API endpoints).
- `$this->redirectToRoute()` — PRG-pattern redirect.
- `$this->file()` — file-download response.

@see https://symfony.com/doc/current/controller.html

## Dependency Injection

- Inject services through the **constructor** — never use `$this->container->get()`.
- Use action-method type hints only for request-scoped values (e.g. `Request`, an Entity via a value resolver).

```php
final class PostController extends AbstractController
{
    public function __construct(
        private readonly PostService $postService,
    ) {}

    #[Route('/post', name: 'post_index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('post/index.html.twig', [
            'posts' => $this->postService->findLatest(),
        ]);
    }
}
```

## Entity Value Resolver

For simple CRUD actions, use the `EntityValueResolver` — it resolves the entity from a route parameter and automatically returns a 404 if not found.

```php
#[Route('/post/{id}', name: 'post_show', methods: ['GET'])]
public function show(Post $post): Response   // automatically resolved + 404 on miss
{
    return $this->render('post/show.html.twig', ['post' => $post]);
}
```

For complex queries (joins, filters), call a Repository method explicitly instead.

## Flash Messages & Redirects

```php
#[Route('/post/{id}/delete', name: 'post_delete', methods: ['POST'])]
#[IsCsrfTokenValid('delete_post', '_token')]
public function delete(Post $post): RedirectResponse
{
    $this->postService->delete($post);
    $this->addFlash('success', 'Post deleted.');

    return $this->redirectToRoute('post_index');
}
```

## What Belongs in a Controller

| Allowed | Not allowed |
|---------|-------------|
| Routing / HTTP method guards | Business rules or calculations |
| A single Service method call | Direct Doctrine queries |
| Form construction and handling | Sending email or notifications |
| Redirects and flash messages | Complex conditional branching |
| Returning a Response | Any logic that could be unit-tested |

@see https://symfony.com/doc/current/best_practices.html#controllers
