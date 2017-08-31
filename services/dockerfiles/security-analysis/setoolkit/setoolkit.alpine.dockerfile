###########################################################################
#		  
#  Build the image:                                               		  
#    $ docker build -t setoolkit -f setoolkit-alpine.dockerfile --no-cache . 					# longer but more accurate
#    $ docker build -t setoolkit -f setoolkit-alpine.dockerfile . 								# faster but increase mistakes
#                                                                 		  
#  Run the container:                                             		  
#    $ docker run -it --rm -v $(pwd)/shared:/shared -p 8888:8888 setoolkit
#    $ docker run -d --name setoolkit -p 8888:8888 -v $(pwd)/shared:/shared setoolkit
#                                                              		  
###########################################################################

## LEVEL1 ###############################################################################################################

FROM frolvlad/alpine-python2
# FROM python:2.7-alpine3.6
LABEL maintainer "Luc Michalski <michalski.luc@gmail.com>"

# user runtime
ARG APP_USER=${APP_USER:-"setoolkit"}
ARG APP_HOME=${APP_HOME:-"/usr/share/$APP_USER"}

# main app

# main component - executable
ARG APP_EXEC_FILENAME=${APP_EXEC_FILENAME:-"setoolkit"}                       		   	   
ARG APP_EXEC_PATH_PREFIX=${APP_EXEC_PATH_PREFIX:-""}                                    
ARG APP_EXEC_PATH_FILE=${APP_EXEC_PATH_FILE:-"$APP_EXEC_PATH_PREFIX$APP_EXEC_FILENAME"}                                    

# main component - config
# local
ARG APP_CONF_LOCAL_FILENAME=${APP_CONF_LOCAL_FILENAME:-"settings-default.yml"}                    
ARG APP_CONF_LOCAL_DIR=${APP_CONF_LOCAL_DIR:-"./shared/conf.d"}     
ARG APP_CONF_LOCAL_FILEPATH=${APP_CONF_LOCAL_FILEPATH:-"${APP_CONF_LOCAL_DIR}/$APP_CONF_LOCAL_FILENAME"}

# remote
ARG APP_CONF_REMOTE_FILENAME=${APP_CONF_REMOTE_FILENAME:-"settings.yml"}                         
ARG APP_CONF_REMOTE_DIR=${APP_CONF_REMOTE_DIR:-"/shared/conf.d"}
ARG APP_CONF_REMOTE_FILEPATH=${APP_CONF_REMOTE_FILEPATH:-"$APP_CONF_REMOTE_DIR/$APP_CONF_REMOTE_FILENAME"}

# install script (will look after install-{SCRIPT_SLUG}.sh)
ARG APP_INSTALL_SCRIPTS=${APP_INSTALL_SCRIPTS:-"setoolkit"}                                  

## container runtime

WORKDIR ${APP_HOME}/${APP_USER}															   
EXPOSE 80 3000 																			   
# VOLUME ["/shared/data/$APP_USER", "/shared/logs/$APP_USER", "/shared/conf.d"] 		   

# shell script switching between modes at runtime
ENTRYPOINT ["/scripts/entrypoint.sh"]                                                      
# available modes: interactive, bash, dev, run
# CMD [""]                                                                                 

## inherited (just for info)
# ENTRYPOINT ["/bin/bash"]								   
# CMD ["setoolkit"]                                                                              

## LEVEL2 ###############################################################################################################

# List of directories and sub-folders to pre-create in the container image
ARG DOCKER_SHARED_FOLDERS=${DOCKER_SHARED_FOLDERS:-"ssl,load,conf.d,logs,data"}
ARG DOCKER_SERVICES=${DOCKER_SERVICES:-"$APP_USER"}

# key dirs
ARG APP_DIR_SHARED_LABEL="${APP_DIR_SHARED_LABEL:-"shared"}"

# List of app-specific APK(s) packages required to install and compile the main component
ARG APK_BUILD_CUSTOM=${APK_BUILD_CUSTOM:-"  python${SETOOLKIT_PY_VERSION_MAJOR}-dev \
                                            py${SETOOLKIT_PY_VERSION_MAJOR}-pexpect \
                                            py${SETOOLKIT_PY_VERSION_MAJOR}-pefile \
                                            py${SETOOLKIT_PY_VERSION_MAJOR}-openssl \
                                            py${SETOOLKIT_PY_VERSION_MAJOR}-cryptography"}

# List of app-specific APK(s) packages required by the main component during the runtime
ARG APK_RUNTIME_CUSTOM=${APK_RUNTIME_CUSTOM:-"tree bash apache2 py${SETOOLKIT_PY_VERSION_MAJOR}-requests php5-apache2 apache2 apache2-ssl"}

# List of app-specific APK(s) packages required by the developers while working inside the project container
ARG APK_INTERACTIVE_CUSTOM=${APK_INTERACTIVE_CUSTOM:-"nano"}

# Set an anonymous user or a restricted user inside the container
ARG HAS_USER=${HAS_USER:-"TRUE"}

# Keep apk packages after DOCKER image build process
ARG IS_KEEP_BUILD=${IS_KEEP_BUILD:-"FALSE"}
ARG IS_KEEP_INTERACTIVE=${IS_KEEP_INTERACTIVE:-"FALSE"}
ARG IS_KEEP_RUNTIME=${IS_KEEP_RUNTIME:-"TRUE"}
ARG IS_KEEP_INSTALL=${IS_KEEP_INSTALL:-"TRUE"}

# Set import status for APK(s) based packages
ARG IS_INTERACTIVE=${IS_INTERACTIVE:-"TRUE"}
ARG IS_RUNTIME=${IS_RUNTIME:-"TRUE"}
ARG IS_BUILD=${IS_BUILD:-"TRUE"}
ARG IS_INSTALL=${IS_INSTALL:-"TRUE"}

#LABEL maintainer="KikePuma" \
#   org.schema-version="1.0" \
#   org.label-schema.name="KikePuma" \
#   org.label-schema.vendor="Cosas de Puma" \
#   org.label-schema.description="SEToolKit Container" \
#   org.label-schema.version="${VERSION}" \
#   org.label-schema.url="https://github.com/CosasDePuma/PearlTheWhale" \
#   org.label-schema.build-date="${BUILD_DATE}" \
#   org.label-schema.docker.cmd="docker run --rm -it -p 80:80 -p 3000:3000 --volume \$HOME:/${APP_DIR_SHARED_LABEL} 
# --volume $HOME/.set:/root/.set --name set cosasdepuma/setoolkit"

## LEVEL3 ###############################################################################################################


# root, /shared
ARG APP_DIR_SHARED_PREFIX_PATH="${APP_DIR_SHARED_PREFIX_PATH:-"/${APP_DIR_SHARED_LABEL}"}" 

# conf.d: config files
ARG APP_DIR_CONFS="${APP_DIR_CONFS:-"$APP_DIR_SHARED_PREFIX_PATH/conf.d"}"                 

# certificates
ARG APP_DIR_CERTS="${APP_DIR_CERTS:-"$APP_DIR_SHARED_PREFIX_PATH/ssl"}"                    

# logs generated by app
ARG APP_DIR_LOGS="${APP_DIR_LOGS:-"$APP_DIR_SHARED_PREFIX_PATH/logs"}"                     

# data generated by app
ARG APP_DIR_DATA="${APP_DIR_DATA:-"$APP_DIR_SHARED_PREFIX_PATH/data"}"                     

# dataset(s) imported/shared
ARG APP_DIR_DICTS="${APP_DIR_DICTS:-"$APP_DIR_SHARED_PREFIX_PATH/dicts"}"                  

# dataset(s) to bulk load/import
ARG APP_DIR_LOAD="${APP_DIR_LOAD:-"$APP_DIR_SHARED_PREFIX_PATH/load"}"                     

# plugin(s) directory
ARG APP_DIR_PLUGINS="${APP_DIR_PLUGINS:-"$APP_DIR_SHARED_PREFIX_PATH/plugins"}"			   

# to export and refined path(s) to share with the container env

# app specific - generated data dir (eg. backup)
ARG APP_DATA_DIR="${APP_DATA_DIR:-"$APP_DIR_DATA/$APP_USER"}"                              

# app specific - log dir
ARG APP_LOGS_DIR="${APP_LOGS_DIR:-"$APP_DIR_LOGS/$APP_USER"}"                              

# app specific - data to load
ARG APP_LOAD_DIR="${APP_LOAD_DIR:-"$APP_DIR_LOAD"}"                                        

# export app specific vars to container global env (nb, there is always on core app to manage in a container)
ENV APP_DATA_DIR=${APP_DATA_DIR} \
    APP_LOGS_DIR=${APP_LOGS_DIR} \
    APP_LOAD_DIR=${APP_LOAD_DIR}

# main component - config filepath
ARG APP_CONF_FILEPATH="${APP_CONF_FILEPATH:-"$APP_DIR_SHARED/conf.d/$APP_CONF_FILENAME"}"

# Download and Install Gosu utility
ARG HELPER_GOSU_VERSION=${HELPER_GOSU_VERSION:-"1.10"}
ARG HELPER_GOSU_FILENAME=${HELPER_GOSU_FILENAME:-"gosu-amd64"}
ARG HELPER_GOSU_FILEPATH=${HELPER_GOSU_FILEPATH:-"/usr/local/sbin/gosu"}
ADD https://github.com/tianon/gosu/releases/download/${HELPER_GOSU_VERSION}/${HELPER_GOSU_FILENAME} /usr/local/sbin/gosu

# List of common APK(s) packages required to install and compile C/C++/Python based projects
ARG APK_BUILD_COMMON=${APK_BUILD_COMMON:-"git coreutils gcc g++ musl-dev make openssl-dev libssh2-dev"}

# List of common APK(s) packages required by the main component during the runtime (eg, ca-certificates, openssl, libssh2)
ARG APK_RUNTIME=${APK_RUNTIME:-"ca-certificates libssh2 openssl"}

# List of common APK(s) packages required by the developers while working inside any dockerized project/app.
ARG APK_INTERACTIVE=${APK_INTERACTIVE:-"nano bash tree"}

# List of APK(s) forwarded from build-args to env vars (nb. need to be toggled by a dev/prod flag)
ENV APK_BUILD_COMMON=${APK_BUILD_COMMON} \
	APK_RUNTIME_COMMON=${APK_RUNTIME_COMMON} \
	APK_INTERACTIVE_COMMON=${APK_INTERACTIVE_COMMON} \	
	APK_BUILD_CUSTOM=${APK_BUILD_CUSTOM} \
	APK_RUNTIME_CUSTOM=${APK_RUNTIME_CUSTOM} \
	APK_INTERACTIVE_CUSTOM=${APK_INTERACTIVE_CUSTOM}

# Set python specifc variables for running apps from the container
# PYTHONUNBUFFERED: Force stdin, stdout and stderr to be totally unbuffered. (equivalent to `python -u`)
# PYTHONHASHSEED: Enable hash randomization (equivalent to `python -R`)
# PYTHONDONTWRITEBYTECODE: Do not write byte files to disk, since we maintain it as readonly. (equivalent to `python -B`)
ENV PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

## LEVEL4 ###############################################################################################################

# Copy the main configuration file to a recurrent and specific destination filepath.
ADD ${APP_CONF_LOCAL_FILEPATH} ${APP_CONF_REMOTE_FILEPATH}
COPY ${APP_CONF_LOCAL_DIR} ${APP_CONF_REMOTE_DIR}

# Copy any specific or generic script/helpers to the container. (nb, need to keep only the ENTRYPOINT script, and its deps, in prod)
COPY ./docker/internal /scripts

## LEVEL5 ###############################################################################################################

# Loop over all app installation tasks (pre-requisites, service to install and build from source, apk(s) removal,... )
# IMPORTANT: 
#  - Try to use only one RUN command to aggregate and run all taks to reduce the number of layers for the container image
#  - Keep container images small (<300Mb)
#  - Prefer Alpine based images
RUN \
    set -x \
    && set -e \
    && chmod +x ${HELPER_GOSU_FILEPATH} \
    \
    && echo -e " *** SQLMAP_PY_VERSION_MAJOR=${SQLMAP_PY_VERSION_MAJOR}" \
    && alias python=python${SQLMAP_PY_VERSION_MAJOR:-"2"} \
    && alias pip=pip${SQLMAP_PY_VERSION_MAJOR:-"2"} \
    \
    && if [ "${HAS_USER}" == "TRUE" ]; then \
        adduser -D ${APP_USER} -h ${APP_HOME} -s /bin/sh ; fi \
    \
    && echo "http://dl-5.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \    
    \
    && if [ "${IS_RUNTIME}" == "TRUE" ]; then \
    apk add --no-cache --no-progress --update ${APK_RUNTIME_COMMON} ${APK_RUNTIME_CUSTOM} ; fi \
    \
    && if [ "${IS_BUILD}" == "TRUE" ]; then \
    apk add --update --no-cache --no-progress --virtual build-deps ${APK_BUILD_COMMON} ${APK_BUILD_CUSTOM} ; fi \
    \
    && if [ "${IS_INTERACTIVE}" == "TRUE" ]; then \
    apk add --update --no-cache --no-progress --virtual interactive-deps ${APK_INTERACTIVE_COMMON} ${APK_INTERACTIVE_CUSTOM} ; fi \
    \
    && for SERVICE in ${DOCKER_SERVICES}; do \
        echo -e "  *** SERVICE: ${SERVICE}" \
        && /bin/bash -c "mkdir -pv ${APP_DIR_SHARED}/{${DOCKER_SHARED_FOLDERS}}/${SERVICE}" ; \
        done \
        && tree ${APP_DIR_SHARED} \
    \
    && find /scripts -name "*.sh" -exec chmod a+x {} \; \
    && cd /scripts \
    && for SCRIPT in ${APP_INSTALL_SCRIPTS}; do \
        echo -e "  *** SCRIPT: ${SCRIPT}" \
        && ./install-${SCRIPT}.sh ; \
        done \
    \
    && if [ "${IS_KEEP_BUILD}" == "TRUE" ]; then \
        apk del --no-cache --no-progress build-deps ; fi \
    \
    && if [ "${IS_KEEP_INTERACTIVE}" == "FALSE" ]; then \
        apk del --no-cache --no-progress interactive-deps ; fi \
    \
    && rm -rf /var/cache/apk/*