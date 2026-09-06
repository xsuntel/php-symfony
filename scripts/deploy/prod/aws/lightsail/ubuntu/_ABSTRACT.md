# Scripts - Deploy - AWS (Amazon Web Service) - Lightsail

## Prod Environment

## Platform

* Linux - [Ubuntu Server](https://ubuntu.com/download/server/)
  * App : PHP
  * Cache : Redis
  * Database : PostgreSQL
  * Message : RabbitMQ
  * Server : Nginx

## Project

* Connect Instance in
  LightSail - [Document](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-ssh-using-terminal.html)

```bash
sudo chmod 400 "${KEY_PATH}/{your name}.pem"

ssh -i "${KEY_PATH}/{your name}.pem/${KEY_NAME}" root@"{HOST}"
```

* Create SSH Key

```bash
rlim@gram:~$ ssh-keygen -f ~/.ssh/id_sourcecommit -t rsa -b 2048
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in id_sourcecommit
Your public key has been saved in id_sourcecommit.pub
The key fingerprint is:
SHA256:zSc6aoecGQlmDx7k+OwS/3u9LgTFpvhi1VRH9U2Q0lk rlim@gram
The key's randomart image is:
+---[RSA 2048]----+
|       . ...ooo=E|
|    .   =  .. +o.|
|   + . *     .  o|
|  . O + .o       |
|   * B oS + .    |
|  . * = .. o     |
|   = o *o.       |
|  . o *.+..      |
|   . o++ oo.     |
+----[SHA256]-----+
rlim@gram:~$
rlim@gram:~$ cat ~/.ssh/id_sourcecommit.pub

rlim@gram:~$ vi ~/.ssh/config
Host devtools.ncloud.com
User [콘솔에 등록된 SSH 키 값]
IdentityFile ~/.ssh/id_sourcecommit
HostkeyAlgorithms +ssh-rsa
PubkeyAcceptedAlgorithms +ssh-rsa
```

* User - adduser : ubuntu

```bash
sudo adduser --home /home/ubuntu --uid 2000 --shell /bin/bash ubuntu

sudo usermod -aG sudo ubuntu
sudo usermod -aG www-data ubuntu
```

```bash
sudo chage -m 3 -M 100 -W 60 -I 30 -E 2099-12-30 ubuntu

sudo grep ubuntu /etc/shadow
sudo grep ubuntu /etc/passwd

sudo chage -l ubuntu
```

### App - Symfony Framework

* Create APP_SECRET

```bash
date | md5
```

* Update default variables in Prod Environment

```bash
vi .env.prod

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Cache - Redis
REDIS_HOST=
REDIS_PORT=6379

# >>>> Database - PostgreSQL
POSTGRES_VERSION=16
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASSWORD=

# >>>> Message - RabbitMQ
RABBITMQ_HOST=
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# >>>> Server - Nginx
NGINX_SCHEME=http
NGINX_HOST=
NGINX_PORT=

# >>>> Utility - Mailer
MAILER_HOST=
MAILER_PORT=
```

* Update packages

```bash
cd ~/Downloads

sudo apt update -y
sudo apt install -y curl git wget unzip
sudo apt autoremove -y
```

* Work Directory

```bash
sudo mkdir -p /var/www
sudo mkdir -p /var/www/github
sudo chown -R "${LOGNAME}":"${LOGNAME}" /var/www/github

cd /var/www/github && if [ -d symfony ]; then rm -rf symfony ; fi
```

* Download this project

```bash
git clone https://github.com/xsuntel/symfony-scripts.git symfony

cd symfony && find ./scripts/ -type f -name "*.sh" -exec chmod 775 {} \;
```

## Deployment

* Deploy this project

```bash
./scripts/deploy/prod/aws/lightsail/ubuntu/deploy.sh
```

* Check status

```bash
./scripts/deploy/prod/aws/lightsail/ubuntu/status.sh
```

### Console

* Cache

```bash
./scripts/base/app/symfony/cache.sh
```

* Migrations

```bash
./scripts/base/app/symfony/database.sh
```

## Reference

### Server

* Cloud
  * AWS (Amazon Web Services)
    * [Lightsail](https://aws.amazon.com/ko/lightsail)
  * AWS Codecommit
    * [Troubleshooting the credential helper](https://docs.aws.amazon.com/codecommit/latest/userguide/troubleshooting-ch.html)
