#!/bin/bash

# Script to set up a Django project on Vagrant.

# Installation settings

PROJECT_NAME=$1

ENVIRONMENT=$2

SU_HOME=/home/$SUDO_USER

VAGRANT_HOME=/vagrant
DB_NAME=$PROJECT_NAME
VIRTUALENV_NAME=$PROJECT_NAME

PROJECT_DIR=$VAGRANT_HOME/$PROJECT_NAME
VIRTUALENV_DIR=$SU_HOME/.virtualenvs/$PROJECT_NAME

PGSQL_VERSION=9.1

chown -R $SUDO_USER:$SUDO_USER $VAGRANT_HOME

# bash environment global setup
cp -p $PROJECT_DIR/etc/install/etc-bash.bashrc /etc/bash.bashrc
su - $SUDO_USER -c "mkdir -p $SU_HOME/.pip_download_cache"

# Need to fix locale so that Postgres creates databases in UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Install essential packages from Apt
apt-get update -y
# Python dev packages
apt-get install -y build-essential python python-dev
# python-setuptools being installed manually
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python
# Dependencies for image processing with PIL
apt-get install -y libjpeg62-dev zlib1g-dev libfreetype6-dev liblcms1-dev
# Git (we'd rather avoid people keeping credentials for git commits in the repo, but sometimes we need it for pip requirements that aren't in PyPI)
apt-get install -y git
# Install nginx, start it, and set it to start on reboot
apt-get install -y nginx
service nginx start
update-rc.d nginx defaults

# Postgresql
if ! command -v psql; then
    apt-get install -y postgresql-$PGSQL_VERSION libpq-dev
    cp $PROJECT_DIR/etc/install/pg_hba.conf /etc/postgresql/$PGSQL_VERSION/main/
chown -R $SUDO_USER:$SUDO_USER $SU_HOME
chown -R $SUDO_USER:$SUDO_USER $VAGRANT_HOME
    /etc/init.d/postgresql reload
fi

# virtualenv global setup
if ! command -v pip; then
    easy_install -U pip
fi
if [[ ! -f /usr/local/bin/virtualenv ]]; then
    pip install virtualenv virtualenvwrapper stevedore virtualenv-clone
fi

cp -p $PROJECT_DIR/etc/install/bashrc $SU_HOME/.bashrc
su - $SUDO_USER -c "mkdir -p $SU_HOME/.pip_download_cache"

# Node.js, CoffeeScript and LESS
if ! command -v npm; then
    wget http://nodejs.org/dist/v0.10.0/node-v0.10.0.tar.gz
    tar xzf node-v0.10.0.tar.gz
    cd node-v0.10.0/
    ./configure && make && make install
    cd ..
    rm -rf node-v0.10.0/ node-v0.10.0.tar.gz
fi
if ! command -v coffee; then
    npm install -g coffee-script
fi
if ! command -v lessc; then
    npm install -g less
fi

# ---

# RabbitMQ install
if ! command -v rabbitmqctl; then
   apt-get install -y rabbitmq-server
fi

# Redis install
if ! command -v redis-server; then
   wget http://download.redis.io/redis-stable.tar.gz
   tar xvzf redis-stable.tar.gz 
   cd redis-stable
   make 
   cp src/redis-server /usr/local/bin/redis-server
   cp src/redis-cli /usr/local/bin/redis-cli
   mkdir /etc/redis
   mkdir /var/redis
   cp utils/redis_init_script /etc/init.d/redis_6379
   cp -p $PROJECT_DIR/redis_6379.conf /etc/redis/6379.conf
   mkdir /var/redis/6379
   update-rc.d redis_6379 defaults
   /etc/init.d/redis_6379 start
   cd ..
fi

# postgresql setup for project
createdb -Upostgres $DB_NAME

# virtualenv setup for project
su - $SUDO_USER -c "/usr/local/bin/virtualenv $VIRTUALENV_DIR && \
    echo $PROJECT_DIR > $VIRTUALENV_DIR/.project && \
    PIP_DOWNLOAD_CACHE=$SU_HOME/.pip_download_cache $VIRTUALENV_DIR/bin/pip install -r $PROJECT_DIR/requirements.txt"

echo "workon $VIRTUALENV_NAME" >> $SU_HOME/.bashrc

# Set execute permissions on manage.py, as they get lost if we build from a zip file
chmod a+x $PROJECT_DIR/manage.py

# Django project setup
su - $SUDO_USER -c "source $VIRTUALENV_DIR/bin/activate && \
    add2virtualenv $PROJECT_DIR && \
    django-admin.py syncdb --noinput --settings=settings.$ENVIRONMENT && \
    django-admin.py migrate --settings=settings.$ENVIRONMENT"
