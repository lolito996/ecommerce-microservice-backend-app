#!/bin/bash
set -e

# If /var/run/docker.sock exists, align the docker group gid to the socket gid
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock || true)
  if [ -n "${DOCKER_GID}" ]; then
    # If socket gid is 0 (root) we avoid changing group ids and instead relax socket perms
    if [ "${DOCKER_GID}" = "0" ]; then
      echo "Docker socket gid is 0 (root) — making socket world-writable to allow access from jenkins user"
      chmod 666 /var/run/docker.sock || true
    else
      if getent group docker >/dev/null 2>&1; then
        CURRENT_GID=$(getent group docker | cut -d: -f3)
        if [ "${CURRENT_GID}" != "${DOCKER_GID}" ]; then
          echo "Updating docker group gid from ${CURRENT_GID} to ${DOCKER_GID}"
          groupmod -g ${DOCKER_GID} docker || true
        fi
      else
        echo "Creating docker group with gid ${DOCKER_GID}"
        groupadd -g ${DOCKER_GID} docker || true
      fi
      usermod -aG docker jenkins || true
      # Try to chown the socket to root:docker and set group rw
      chown root:docker /var/run/docker.sock || true
      chmod 660 /var/run/docker.sock || true
    fi
  fi
fi

# Exec the original jenkins entrypoint (bundled in the image)
if [ -x /usr/local/bin/jenkins.sh ]; then
  exec /usr/local/bin/jenkins.sh "$@"
else
  exec java -jar /usr/share/jenkins/jenkins.war
fi
