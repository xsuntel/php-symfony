# Scripts - Console Commands

## App - Symfony Framework

### Console

* [Running Commands](https://symfony.com/doc/current/console.html)

```bash
symfony console list
```

#### Debug

* config

```bash
symfony console debug:config
```

* dotenv

```bash
symfony console debug:dotenv
```

* firewall

```bash
symfony console debug:firewall main
```

* autowiring

```bash
symfony console debug:autowiring --all
```

* container

```bash
symfony console debug:container
```

* Router

```bash
symfony console debug:router
```

* Event

```bash
symfony console debug:event-dispatcher

symfony console debug:event-dispatcher kernel.exception

symfony console debug:event-dispatcher Security
```

* Form

```bash
symfony console debug:form
```

* Translation

```bash
symfony console debug:translation ko
```

* Twig

```bash
symfony console debug:twig-component
```

#### Cache

* Console

```bash
symfony console cache:pool:list


symfony console cache:pool:clear --all
```

## Reference

### Tools

* Symfony             - [Console Commands](https://symfony.com/doc/current/console.html)
