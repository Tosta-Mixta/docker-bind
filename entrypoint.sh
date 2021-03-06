#!/bin/bash
set -e

ROOT_PASSWORD=${ROOT_PASSWORD:-password}

BIND_DATA_DIR=${DATA_DIR}/bind

create_bind_data_dir() {
  mkdir -p ${BIND_DATA_DIR}

  # On popule la config par defaut de bind, si elle existe pas.
  if [ ! -d ${BIND_DATA_DIR}/etc ]; then
    mv /etc/bind ${BIND_DATA_DIR}/etc
  fi

  rm -rf /etc/bind
  ln -sf ${BIND_DATA_DIR}/etc /etc/bind
  chmod -R 0775 ${BIND_DATA_DIR}
  chown -R ${BIND_USER}:${BIND_USER} ${BIND_DATA_DIR}

  if [ ! -d ${BIND_DATA_DIR}/lib ]; then
    mkdir -p ${BIND_DATA_DIR}/lib
    chown ${BIND_USER}:${BIND_USER} ${BIND_DATA_DIR}/lib
  fi

  rm -rf /var/lib/bind
  ln -sf ${BIND_DATA_DIR}/lib /var/lib/bind
}

set_root_passwd() {
  echo "root:$ROOT_PASSWORD" | chpasswd
}

create_pid_dir() {
  mkdir -m 0775 -p /var/run/named
  chown root:${BIND_USER} /var/run/named
}

create_bind_cache_dir() {
  mkdir -m 0775 -p /var/cache/bind
  chown root:${BIND_USER} /var/cache/bind
}

create_pid_dir
create_bind_data_dir
create_bind_cache_dir

# On autorise les arguments passé a bind
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == named || ${1} == $(which named) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# Le comportement normal est de lancer bind
if [[ -z ${1} ]]; then
    set_root_passwd

  echo "Starting Bind..."
  exec $(which named) -u ${BIND_USER} -g ${EXTRA_ARGS}
else
  exec "$@"
fi