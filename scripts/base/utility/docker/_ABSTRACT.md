# Scripts - Console Commands

## Docker - Command

### Global

* Check information

```bash
docker version
```

* Check information

```bash
docker info
```

```bash
docker system prune -a -f --filter "label=purpose=webapp"
```

### Process

* Check information

```bash
docker ps -a
```

```bash
docker ps --filter "id=${CONTAINER_ID}"
```

### Network

* Check information

```bash
docker network ls
```

```bash
docker port "${CONTAINER_ID}"
```

### Image

* Check information

```bash
docker image ls
```

```bash
docker image inspect "${IMAGE_NAME}:${TAG_NAME}"
```

### Container

* Check information

```bash
docker container ls
```

* Check information

```bash
docker logs "${CONTAINER_ID}"
```

### Tools

* Clear dontainers

```bash
# >>>> Docker - containers down
docker compose -f "docker-compose.yml" --env-file ".env.app" --env-file "docker-compose.env" down

# >>>> Docker - containers clear
docker network prune -f

# >>>> Docker - system clear
# docker system prune
```
