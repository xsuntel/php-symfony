# Scripts - Console Commands

## Database - PostgreSQL

### Connect

* Configure the database

```bash
[root@localhost] sudo -i -u postgres
[sudo] password for user: {password}

postgres@localhost:~$ psql
psql (xx.y)
Type "help" for help.

postgres=# create user symfony password '!ChangeMe!' superuser;
CREATE ROLE
postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 symfony   | Superuser                                                  | {}

postgres=# \q

```

* Change the user's password

```bash
sudo -i -u postgres
[sudo] password for user: {password}

postgres@localhost:~$ psql
psql (xx.y)
Type "help" for help.

postgres=# alter user {user_name} password {user_password}

postgres=# \q

```

### Database

* Delete

```bash
postgres=# \l

postgres=# drop database {name}
```

* Rename

```bash
postgres=# \l

postgres=# ALTER DATABASE {old_name} RENAME TO {new_name};
```
