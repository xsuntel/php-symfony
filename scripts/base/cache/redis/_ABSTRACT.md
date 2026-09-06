# Scripts - Console Commands

## Cache - Redis

* Linux - Ubuntu

```bash
sudo snap install redisinsight
```

### Connect

* Remote Host

```bash
redis-cli -h 127.0.0.1 -p 6379
```

* Information

```bash
redis-cli info
```

* help

```bash
redis-cli help
```

* Monitoring

```bash
redis-cli monitor
```

#### CRUD

* Keys

```bash
keys *{keyword}*
```

* Value

```bash
get {value}
```

```bash
mget {value} {value} ...
```

* Delete

```bash
del {value}
```

```bash
flushall
```

## Tools

* [Redis Insight](https://redis.io/insight/)
