---
paths:
  - "app/src/Form/**/*.php"
---

# Form Rule

@see https://symfony.com/doc/current/forms.html

## Form Class Definition

- Define every form as a PHP class that extends `AbstractType`.
- Do not define a form inline inside a controller.
- Mark Form type classes `final`.

```php
final class PostType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('title', TextType::class)
            ->add('content', TextareaType::class)
            ->add('category', EntityType::class, [
                'class' => Category::class,
                'choice_label' => 'name',
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults(['data_class' => PostDto::class]);
    }
}
```

## DTO Pattern (Preferred Over Binding Directly to an Entity)

Bind the form to a **DTO class**, not an Entity. This decouples the HTTP layer from the persistence model and prevents sensitive fields (e.g. `id`, `createdAt`) from being exposed.

```php
final class PostDto
{
    #[Assert\NotBlank]
    #[Assert\Length(min: 10, max: 255)]
    public string $title = '';

    #[Assert\NotBlank]
    public string $content = '';
}
```

Use the DTO in the controller, then map it to an Entity in the Service:

```php
public function new(Request $request): Response
{
    $dto = new PostDto();
    $form = $this->createForm(PostType::class, $dto);
    $form->handleRequest($request);

    if ($form->isSubmitted() && $form->isValid()) {
        $this->postService->create($dto);
        return $this->redirectToRoute('post_index');
    }

    return $this->render('post/new.html.twig', ['form' => $form]);
}
```

Specify the DTO class via the `data_class` option:

```php
public function configureOptions(OptionsResolver $resolver): void
{
    $resolver->setDefaults([
        'data_class' => CreatePostDto::class,
    ]);
}
```

## Validation Constraints

- Define validation constraints on the **DTO or Entity class**, not on the Form field definition.
- This applies the constraints consistently no matter how the object is populated (Form, API, CLI).

```php
// Correct — constraints on the DTO
final class PostDto
{
    #[Assert\NotBlank]
    #[Assert\Length(min: 10)]
    public string $title = '';
}

// Wrong — constraints on the form field
$builder->add('title', TextType::class, [
    'constraints' => [new NotBlank()],   // avoid this
]);
```

## CSRF Protection

- Symfony Form enables CSRF protection by default — never disable it (except for API-only forms).
- Custom token field name: use the `csrf_field_name` option.

@see https://symfony.com/doc/current/security/csrf.html

## Validation Groups

Use validation groups when a scenario (create vs. edit) needs different validation rules. The `Default` group always applies.

```php
// Entity
#[Assert\NotBlank(groups: ['create'])]
#[Assert\Length(min: 8, groups: ['create', 'edit'])]
private string $password;

// FormType
public function configureOptions(OptionsResolver $resolver): void
{
    $resolver->setDefaults([
        'validation_groups' => ['Default', 'create'],
    ]);
}
```

@see https://symfony.com/doc/current/validation/groups.html

## Submit Buttons

- Add submit buttons in the **Twig template**, not in the Form class or the controller.
- Exception: add them in the controller when multiple submit buttons trigger different actions.

```twig
{# post/new.html.twig #}
{{ form_start(form) }}
    {{ form_widget(form) }}
    <button type="submit">Save</button>
{{ form_end(form) }}
```

## Single-Action Pattern

Handle both rendering and processing in **a single controller action**:

```php
#[Route('/post/new', name: 'post_new', methods: ['GET', 'POST'])]
#[IsCsrfTokenValid('post_form', '_token')]
public function new(Request $request): Response
{
    $dto = new PostDto();
    $form = $this->createForm(PostType::class, $dto);
    $form->handleRequest($request);

    if ($form->isSubmitted() && $form->isValid()) {
        $this->postService->create($dto);
        $this->addFlash('success', 'Post created.');
        return $this->redirectToRoute('post_index');
    }

    return $this->render('post/new.html.twig', ['form' => $form]);
}
```

@see https://symfony.com/doc/current/best_practices.html#forms
