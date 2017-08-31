###########################################################################
#		  
#  Build the image:                                               		  
#    $ docker build -t aiohttp-admin -f aiohttp_admin.dockerfile --no-cache . 	# longer but more accurate
#    $ docker build -t aiohttp-admin -f aiohttp_admin.dockerfile . 				# faster but increase mistakes
#                                                                 		  
#  Run the container:                                             		  
#    $ docker run -it --rm -v $(pwd)/shared:/shared -p 9001:9001 aiohttp-admin
#    $ docker run -d --name aiohttp-admin -p 9001:9001 -v $(pwd)/shared:/shared aiohttp-admin
#                                                              		  
###########################################################################

FROM alpine:3.6
LABEL maintainer "Luc Michalski <michalski.luc@gmail.com>"

EXPOSE 9001
VOLUME ["/shared"] 
# , "/etc/aiohttp_admin"]
WORKDIR /app/aiohttp_admin

ARG AIOHTTP_ADMIN_DATA_DIR=${AIOHTTP_ADMIN_DATA_DIR:-"/shared/data/aiohttp_admin"}
ARG AIOHTTP_ADMIN_LOGS_DIR=${AIOHTTP_ADMIN_LOGS_DIR:-"/shared/logs/aiohttp_admin"}
ARG AIOHTTP_ADMIN_LOAD_DIR=${AIOHTTP_ADMIN_LOAD_DIR:-"/shared/load"}

ENV AIOHTTP_ADMIN_DATA_DIR=${AIOHTTP_ADMIN_DATA_DIR} \
    AIOHTTP_ADMIN_LOGS_DIR=${AIOHTTP_ADMIN_LOGS_DIR} \
    AIOHTTP_ADMIN_LOAD_DIR=${AIOHTTP_ADMIN_LOAD_DIR}

ENTRYPOINT ["/scripts/entrypoint.sh"]
# CMD [""]

# app configuration
ARG APP_CONF_FILENAME=${APP_CONF_FILENAME:-"settings-default.yml"}
ARG APP_CONF_FILEPATH=${APP_CONF_FILEPATH:-"$APP_DIR_SHARED/conf.d/$APP_CONF_FILENAME"}

# Set env variables
ARG DOCKER_SERVICES=${DOCKER_SERVICES:-"aiohttp/admin"}
ARG DOCKER_SHARED_FOLDERS=${DOCKER_SHARED_FOLDERS:-"ssl,load,conf.d,logs,data"}

# install script (will look after install-{SCRIPT_SLUG}.sh) 
# available: pip3 aiohttp_admin berkleydb libgit2 faiss
ARG APP_INSTALL_SCRIPTS=${APP_INSTALL_SCRIPTS:-"pip3 libgit2 berkleydb aiohttp_admin"}

# Define app specific APK(s) packages to install
ARG APK_BUILD_CUSTOM=${APK_BUILD_CUSTOM:-"		tree gcc g++ musl-dev linux-headers coreutils build-base \
                                                libxslt-dev libxml2-dev libffi-dev jpeg-dev libpng-dev tar curl wget \
                                                nodejs-current-npm yarn cmake pkgconfig libtool file \
                                                mongo-c-driver-dev sqlite-dev mysql-dev postgresql-dev \
                                                python3-dev"}

ARG APK_RUNTIME_CUSTOM=${APK_RUNTIME_CUSTOM:-"	make libxslt libxml2 libressl jpeg libpng \
                                                nodejs-current \
                                                python3 \
                                                postgresql postgresql-client postgresql-contrib \
												mysql-client \
												sqlite \
												mongo-c-driver"}

ARG APK_INTERACTIVE_CUSTOM=${APK_INTERACTIVE_CUSTOM:-"jq"}

# Set import status for apk based packages
ARG IS_INTERACTIVE=${IS_INTERACTIVE:-"TRUE"}
ARG IS_RUNTIME=${IS_RUNTIME:-"TRUE"}
ARG IS_BUILD=${IS_BUILD:-"TRUE"}
ARG IS_INSTALL=${IS_INSTALL:-"TRUE"}
ARG HAS_USER=${HAS_USER:-"FALSE"}

# Install Gosu to /usr/local/bin/gosu
ARG HELPER_GOSU_VERSION=${HELPER_GOSU_VERSION:-"1.10"}
ARG HELPER_GOSU_FILENAME=${HELPER_GOSU_FILENAME:-"gosu-amd64"}
ARG HELPER_GOSU_FILEPATH=${HELPER_GOSU_FILEPATH:-"/usr/local/sbin/gosu"}
ADD https://github.com/tianon/gosu/releases/download/${HELPER_GOSU_VERSION}/${HELPER_GOSU_FILENAME} /usr/local/sbin/gosu

# Define common APK(s) packages to install
ARG APK_BUILD_COMMON=${APK_BUILD_COMMON:-"coreutils gcc g++ musl-dev make cmake openssl-dev libssh2-dev autoconf automake"}
ARG APK_RUNTIME=${APK_RUNTIME:-"ca-certificates git libssh2 openssl"}
ARG APK_INTERACTIVE=${APK_INTERACTIVE:-"nano bash tree"}

# restricted user
ARG APP_USER=${APP_USER:-"app"}
ARG APP_HOME=${APP_HOME:-"/app"}

# key dirs
ARG APP_DIR_SHARED=${APP_DIR_SHARED:-"/shared"}
ARG APP_DIR_CONFS=${APP_DIR_CONFS:-"/shared/conf.d"}
ARG APP_DIR_CERTS=${APP_DIR_CERTS:-"/shared/ssl"}
ARG APP_DIR_DATA=${APP_DIR_DATA:-"/shared/data"}
ARG APP_DIR_DICTS=${APP_DIR_DICTS:-"/shared/dicts"}
ARG APP_DIR_LOAD=${APP_DIR_LOAD:-"/shared/load"}
ARG APP_DIR_LOGS=${APP_DIR_LOGS:-"/shared/logs"}
ARG APP_DIR_PLUGINS=${APP_DIR_PLUGINS:-"/shared/plugins"}

# Add to env the apk build args for switching between entrypoints with the right amount of dependencies loaded
ENV APK_BUILD_COMMON=${APK_BUILD_COMMON} \
	APK_RUNTIME=${APK_RUNTIME} \
	APK_INTERACTIVE=${APK_INTERACTIVE} \	
	APK_BUILD_CUSTOM=${APK_BUILD_CUSTOM} \
	APK_RUNTIME_CUSTOM=${APK_RUNTIME_CUSTOM} \
	APK_INTERACTIVE_CUSTOM=${APK_INTERACTIVE_CUSTOM}

# PYTHONUNBUFFERED: Force stdin, stdout and stderr to be totally unbuffered. (equivalent to `python -u`)
# PYTHONHASHSEED: Enable hash randomization (equivalent to `python -R`)
# PYTHONDONTWRITEBYTECODE: Do not write byte files to disk, since we maintain it as readonly. (equivalent to `python -B`)
ENV PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/" \
    PYTHON_PIP_VERSION=${PYTHON_PIP_VERSION:-"9.0.1"}

# Copy the configuration file (with logs, data and config dir vars updated)
ADD ./shared/conf.d/${APP_CONF} ${APP_SHARED}/conf.d/${APP_CONF}

COPY ./docker/internal/ /scripts
COPY ./shared/ /shared/

# --allow-untrusted
RUN \
    set -x \
    && set -e \
    && chmod +x ${HELPER_GOSU_FILEPATH} \
    \
    && if [ "${HAS_USER}" == "TRUE" ]; then \
        adduser -D ${APP_USER} -h ${APP_HOME} -s /bin/sh ; fi \
    \
        && echo "http://dl-5.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \    
    \
    && if [ "${IS_RUNTIME}" == "TRUE" ]; then \
    apk add --no-cache --no-progress --update ${APK_RUNTIME} ${APK_RUNTIME_CUSTOM} ; fi \
    \
    && if [ "${IS_BUILD}" == "TRUE" ]; then \
    apk add --update --no-cache --no-progress --virtual build-deps ${APK_BUILD} ${APK_BUILD_CUSTOM} ; fi \
    \
    && if [ "${IS_INTERACTIVE}" == "TRUE" ]; then \
    apk add --update --no-cache --no-progress --virtual interactive-deps ${APK_INTERACTIVE} ${APK_INTERACTIVE_CUSTOM} ; fi \
    \
    && for SERVICE in ${DOCKER_SERVICES}; do \
        echo -e "  *** SERVICE: ${SERVICE}" \
        && /bin/bash -c "mkdir -pv ${APP_DIR_SHARED}/{${DOCKER_SHARED_FOLDERS}}/${SERVICE}" ; \
        done \
        && tree ${APP_DIR_SHARED} \
    \
    && chmod a+x /scripts/*.sh \
    && cd /scripts \
    && for SCRIPT in ${APP_INSTALL_SCRIPTS}; do \
        echo -e "  *** SCRIPT: ${SCRIPT}" \
        && ./install-${SCRIPT}.sh ; \
        done \
    \
    && if [ "${IS_BUILD}" == "TRUE" ]; then \
    apk --no-cache --no-progress del build-deps ; fi \
    \
    && rm -rf /var/cache/apk/*


