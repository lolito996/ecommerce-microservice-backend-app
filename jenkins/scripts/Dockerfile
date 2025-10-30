FROM jenkins/jenkins:lts-jdk11

USER root

# Instalar docker CLI y docker-compose dentro del contenedor
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	   ca-certificates \
	   curl \
	   gnupg2 \
	   lsb-release \
	   docker.io \
	   docker-compose \
	&& rm -rf /var/lib/apt/lists/*

# Crear grupo docker y añadir el usuario jenkins (gid ajustado en entrypoint)
RUN groupadd -f docker || true && usermod -aG docker jenkins || true

# Copiar entrypoint que ajusta GID del grupo docker al del socket montado
COPY jenkins-entrypoint.sh /usr/local/bin/jenkins-entrypoint.sh
RUN chmod +x /usr/local/bin/jenkins-entrypoint.sh

USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-entrypoint.sh"]