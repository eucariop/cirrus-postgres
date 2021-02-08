# vim:set ft=dockerfile:
FROM registry.access.redhat.com/ubi8/ubi:8.3-227

# General variables
ENV IMAGE_NAME=postgres \
    IMAGE_SUMMARY="PostgreSQL Container Images" \
    IMAGE_DESCRIPTION="This Docker image contains PostgreSQL \
						based on RedHat Universal Base Images (UBI) 8." \
    IMAGE_TITLE="Postgres 9.6" \
    IMAGE_SERVICE_PORT="5432" \
    IMAGE_SERVICE_NAME="postgres"

# Container variables
ENV CTR_USER=postgres \
    CTR_USER_ID="26" \
    CTR_HOME=/var/lib/postgresql \
    CTR_CMD="postgres" \
    CTR_SCRIPTS_PATH=/usr/share/container-scripts/postgresql

# Component bash variables
ENV POSTGRES_VERSION="9.6.20-2PGDG.rhel8" \
    POSTGRES_VER_SHORT="96" \
    POSTGRES_PORT=${IMAGE_SERVICE_PORT} \
    POSTGRES_RUN=/var/run/postgresql \
    POSTGRES_HOME=${CTR_HOME} \
    POSTGRES_DATA="${CTR_HOME}/data"

# Frequent environment variables
ENV HOME="${CTR_HOME}" \
    PGUSER="$CTR_USER" \
    LANG="en_US.UTF-8"

COPY root/ /
ENV OS_INSTALL_PKGS="hostname rsync tar gettext bind-utils nss_wrapper glibc-locale-source glibc-langpack-en"
ENV	POSTGRES_INSTALL_PKGS="postgresql96-9.6.20-2PGDG.rhel8 postgresql96-contrib-9.6.20-2PGDG.rhel8 postgresql96-server-9.6.20-2PGDG.rhel8 postgresql96-libs-9.6.20-2PGDG.rhel8"

RUN set -xe ; \
	yum -y reinstall glibc-common ; \
	yum -y install ${OS_INSTALL_PKGS} ; \
	yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm ; \
	yum -y --setopt=tsflags=nodocs install ${POSTGRES_INSTALL_PKGS} ; \
	yum -y clean all --enablerepo='*'

# CMD ["/bin/bash"]

RUN set -eux; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/pgsql-9.6/share/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/pgsql-9.6/share/postgresql.conf.sample

RUN set -xeu ; \
	localedef -f UTF-8 -i en_US en_US.UTF-8 ; \
	test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)" ; \
	mkdir -p ${POSTGRES_RUN} ; \
	chown ${CTR_USER}:${CTR_USER} ${POSTGRES_RUN} ; \
	chmod 0755 ${POSTGRES_RUN}

ENV PATH $PATH:/usr/pgsql-9.6/bin

RUN mkdir -p ${POSTGRES_RUN} && chown -R ${CTR_USER}:${CTR_USER} ${POSTGRES_RUN} && chmod 2777 ${POSTGRES_RUN}

ENV PGDATA ${POSTGRES_DATA}/pgdata
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R ${CTR_USER}:${CTR_USER} "$PGDATA" && chmod 777 "$PGDATA"
VOLUME ${POSTGRES_DATA}

RUN mkdir /docker-entrypoint-initdb.d

USER ${CTR_USER_ID}

ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE ${CTR_USER_ID}
CMD ["${CTR_CMD}"]

# Labels
LABEL name="${IMAGE_NAME}" \
      summary="${IMAGE_SUMMARY}" \
      description="${IMAGE_DESCRIPTION}" \
      maintainer="Eucario Padro <eucario.padro@ibm.com>" \
      org.opencontainers.image.title="${IMAGE_TITLE}" \
      org.opencontainers.image.authors="Eucario Padro <eucario.padro@ibm.com>" \
      org.opencontainers.image.description="${IMAGE_DESCRIPTION}" \
      org.opencontainers.image.version="0.1" \
      io.k8s.description="${IMAGE_DESCRIPTION}" \
      io.k8s.display-name="${IMAGE_TITLE}" \
      io.openshift.expose-services="${IMAGE_SERVICE_PORT}:${IMAGE_SERVICE_NAME}" \
      io.openshift.tags="${IMAGE_NAME},postgres,postgres-${POSTGRES_VER_SHORT},postgres${POSTGRES_VER_SHORT}"