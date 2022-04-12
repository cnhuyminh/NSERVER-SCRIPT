#!/bin/bash

# Postgres
curDir="$PWD"
echo "Enter web domain: "
read webDomain < /dev/tty

echo "Postgres Host (default=127.0.0.1 => install postgres in local): "
read pgHost < /dev/tty

if [ "$pgHost" == "" ]
then
	pgHost="127.0.0.1"
fi

pgPort="5432"
if [ "$pgHost" != "127.0.0.1" ]
then
	echo "Postgres Port (default=5432): "
	read pgHost < /dev/tty
	if [ "$pgPort" == "" ]
	then
		pgHost="5432"
	fi
fi

echo "Postgres username (default=postgres) : "
read pgUsername < /dev/tty

if [ "$pgUsername" == "" ]
then
	pgUsername="postgres"
fi

echo "Postgres password (default=postgres) : "
read pgPassword < /dev/tty

if [ "$pgPassword" == "" ]
then
	pgPassword="postgres"
fi

# Redis
echo "Redis Host (default=127.0.0.1 => install redis in local): "
read redisHost < /dev/tty

if [ "$redisHost" == "" ]
then
	redisHost="127.0.0.1"
fi

redisPort="6379"
redisUsername=""
redisPassword=""
if [ "$redisHost" != "127.0.0.1" ]
then
	echo "Redis Port (default=6379): "
	read redisPort < /dev/tty
	if [ "$redisPort" == "" ]
	then
		redisPort="6379"
	fi

	echo "Redis username : "
	read redisUsername < /dev/tty

	echo "Redis password : "
	read redisPassword < /dev/tty
fi

rm -rf "server"
mkdir "server"
chmod -R u+rwx,g-rwx,o-rwx "server"

# tao thu muc tmp 
mkdir "tmp"

sudo systemctl stop postgresql-14
sleep 10

# install postgres
if [ "$pgHost" == "127.0.0.1" ]
then
	echo "Install Postgres 14"
	sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

	sudo dnf -qy module disable postgresql
	sudo dnf install -y postgresql14-server
	sudo dnf install -y postgresql14-contrib

	installDir="$curDir/postgres"

	# remove postgres data directory
	rm -rf "$installDir"
	mkdir "$installDir"

	chown -R postgres:postgres "$installDir"
	chmod -R u+rwx,g-rwx,o-rwx "$installDir"

	rm -rf "/var/lib/pgsql/14/data"
	ln -s "$installDir" "/var/lib/pgsql/14/data"

	chown -R postgres:postgres "/var/lib/pgsql/14/data"
	chmod -R u+rwx,g-rwx,o-rwx "/var/lib/pgsql/14/data"

	# write password file
	echo "$pgPassword" > "$curDir/tmp/pass.txt"

	# init postgres
	echo "Init Postgres"
	sudo -u postgres /usr/pgsql-14/bin/initdb --username="$pgUsername" --pwfile="$curDir/tmp/pass.txt" --locale=en_US.UTF-8 --encoding=utf8 --pgdata="/var/lib/pgsql/14/data"
	rm -rf "$curDir/tmp/pass.txt"

	sudo systemctl enable postgresql-14
	sleep 10
fi

if [ "$redisHost" == "127.0.0.1" ]
then
	sudo systemctl stop redis
	sleep 10

	# install redis
	echo "Install Redis"
	sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y

	sudo dnf -qy module disable redis
	sudo dnf module enable redis:remi-6.2 -y
	sudo dnf install redis -y

	sudo systemctl enable redis
	sleep 10
fi

# storagePath
mkdir "$curDir/server/storage"

# giai nen
unzip -o "$curDir/sources/NSERVER/installer.zip" -d "server"

# giai nen
unzip -o "$curDir/sources/RELEASE/NSERVER.zip" -d "server/dist/core/debug"

mkdir -p "$curDir/server/dist/apps/ncdn/debug"
unzip -o "$curDir/sources/RELEASE/NCDN.zip" -d "$curDir/server/dist/apps/ncdn/debug"
cd "$curDir/server/dist/apps/ncdn/debug"
npm install
cd "$curDir"

mkdir -p "$curDir/server/dist/apps/ndev/debug"
unzip -o "$curDir/sources/RELEASE/NDEV.zip" -d "$curDir/server/dist/apps/ndev/debug"
cd "$curDir/server/dist/apps/ndev/debug"
npm install
cd "$curDir"

mkdir -p "$curDir/server/dist/package/ncdn/debug"
cd "$curDir/server/dist/package/ncdn/debug"
echo "{\"name\":\"ncdn\",\"version\":\"1.0.0\",\"private\":true,\"scripts\":{},\"dependencies\":{\"vcore\":\"$curDir/server/dist/apps/ncdn/debug\",\"ncore\":\"$curDir/server/dist/core/debug/ncore\",\"nlib\":\"$curDir/server/dist/core/debug/nlib\",\"plugins\":\"$curDir/server/dist/core/debug/plugins\"},\"devDependencies\":{}}" > "package.json"
npm install
cd "$curDir"

mkdir -p "$curDir/server/dist/package/ndev/debug"
cd "$curDir/server/dist/package/ndev/debug"
echo "{\"name\":\"ndev\",\"version\":\"1.0.0\",\"private\":true,\"scripts\":{},\"dependencies\":{\"vcore\":\"$curDir/server/dist/apps/ndev/debug\",\"ncore\":\"$curDir/server/dist/core/debug/ncore\",\"nlib\":\"$curDir/server/dist/core/debug/nlib\",\"plugins\":\"$curDir/server/dist/core/debug/plugins\"},\"devDependencies\":{}}" > "package.json"
npm install
cd "$curDir"

# ok
sudo systemctl start postgresql-14
sudo systemctl start redis
sleep 10

# config
PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname=postgres --username=$pgUsername -c 'CREATE DATABASE "db-ndev"'
PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname="db-ndev" --username=$pgUsername -c "CREATE EXTENSION IF NOT EXISTS ltree"
PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname="db-ndev" --username=$pgUsername -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname=postgres --username=$pgUsername -c 'CREATE DATABASE "db-shared-tmp"'
PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname="db-shared-tmp" --username=$pgUsername -c "CREATE EXTENSION IF NOT EXISTS ltree"
PGPASSWORD="$pgPassword" psql --host=$pgHost --port=$pgPort --dbname="db-shared-tmp" --username=$pgUsername -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'

echo "{\"apps\":{\"ndev\":{\"source\":\"ndev\",\"binds\":[\"$webDomain\"],\"domain\":{\"server\":\"$webDomain\"},\"connections\":{\"default\":{\"username\":\"$pgUsername\",\"password\":\"$pgPassword\",\"database\":\"db-ndev\"}},\"enabled\":true}}}" > "server/config.apps.json"

echo "{\"defaults\":{\"connections\":{\"default\":{\"dialect\":\"postgres\"},\"shared\":{\"dialect\":\"postgres\",\"username\":\"$pgUsername\",\"password\":\"$pgPassword\",\"database\":\"db-shared-tmp\"}},\"redis\":{\"socket\":{\"host\":\"$redisHost\",\"port\":$redisPort},\"username\":\"$redisUsername\",\"password\":\"$redisPassword\"}},\"postgres\":{\"username\":\"$pgUsername\",\"password\":\"$pgPassword\"}}" > "server/config.db.json"

echo "{\"defaults\":{\"timezone\":\"America/Los_Angeles\",\"clientSecret\":\"OGRSU1FqVkk3S3NDeVdSeVNCMEo3STZvclFFaVdGYkk=\",\"cdnKey\":\"7zHJA5DawE3DpgmK3CfvkJ7dK2JEcGj9\",\"domain\":{\"cdn\":\"$webDomain\"},\"smtp\":{},\"connections\":{\"default\":{\"host\":\"$pgHost\",\"port\":$pgPort},\"shared\":{\"host\":\"$pgHost\",\"port\":$pgPort}},\"redis\":{\"socket\":{\"host\":\"$redisHost\",\"port\":$redisPort},\"username\":\"$redisUsername\",\"password\":\"$redisPassword\"},\"localesInfo\":{\"vi\":{\"code\":\"vi\",\"codes\":[\"vi\",\"vi-VN\"],\"file\":\"default\",\"name\":\"Tiếng Việt (US)\",\"icon\":\"VI\",\"format\":\"en-US\"}}},\"paths\":{\"core\":\"dist/core/debug\"},\"apps\":{\"ndev\":{\"origin\":\"*\",\"keys\":{\"7zHJA5DawE3DpgmK3CfvkJ7dK2JEcGj9\":\"*\"},\"plugins\":[\"moment\",\"core\",\"adminui\",\"cdn\"]}},\"postgres\":{\"username\":\"$pgUsername\",\"password\":\"$pgPassword\"},\"ddns\":{},\"etag\":\"0000\",\"packages\":{}}" > "server/config.defaults.json"

# disable dev
echo '{"dev":false}' > "server/config.dev.json"

# service
sudo systemctl stop vnvnweb
vnvnweb="/lib/systemd/system/vnvnweb.service"
sudo rm -rf "$vnvnweb"

echo "[Unit]" > $vnvnweb
echo "Description=VNVN WEB" >> $vnvnweb
echo "After=network.target" >> $vnvnweb
echo "Wants=postgresql-14.service" >> $vnvnweb
echo "Wants=redis.service" >> $vnvnweb

echo "[Service]" >> $vnvnweb
echo "Type=simple" >> $vnvnweb
echo "Environment=NODE_ENV=production" >> $vnvnweb
echo "WorkingDirectory=$curDir/server" >> $vnvnweb
echo "ExecStart=/usr/bin/node $curDir/server/index.js" >> $vnvnweb
echo "Restart=on-failure" >> $vnvnweb
echo "KillMode=mixed" >> $vnvnweb
echo "KillSignal=SIGINT" >> $vnvnweb

echo "[Install]" >> $vnvnweb
echo "WantedBy=multi-user.target" >> $vnvnweb

chmod +x $vnvnweb
sudo systemctl enable vnvnweb

sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --zone=public --permanent --add-service=https
sudo firewall-cmd --reload

# install npm
cd "server"
npm install

# sudo systemctl start vnvnweb

echo "=================== INSTALL COMPLETE "==================="
