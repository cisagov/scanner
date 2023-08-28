FROM python:3.10.13-slim-bullseye

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
LABEL org.opencontainers.image.authors="vm-fusion-dev-group@trio.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"

###
# Unprivileged user setup variables
###
# TODO: Change this to 2048.  See cisagov/orchestrator#130 for more
# details.
ARG CISA_UID=421
ARG CISA_GID=${CISA_UID}
ARG CISA_USER="cisa"
ENV CISA_GROUP=${CISA_USER}
ENV CISA_HOME="/home/${CISA_USER}"

###
# Upgrade the system
###
RUN apt-get update --quiet --quiet \
    && apt-get upgrade --quiet --quiet

###
# Create unprivileged user
###
RUN groupadd --system --gid ${CISA_GID} ${CISA_GROUP} \
    && useradd --system --uid ${CISA_UID} --gid ${CISA_GROUP} --comment "${CISA_USER} user" --create-home ${CISA_USER}

###
# Dependencies
#
# We need bash because it is not pre-installed on Alpine Linux and
# scan.sh is a bash script.  We need redis-tools so we can use
# redis-cli to communicate with redis.
#
# Install dependencies are only needed for software installation and
# will be removed at the end of the build process.
###
ENV DEPS \
    bash \
    redis-tools
ENV INSTALL_DEPS \
    curl
RUN apt-get install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
    $DEPS $INSTALL_DEPS

###
# Make sure pip, setuptools, and wheel are the latest versions
#
# Note that we use pip3 --no-cache-dir to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN pip3 install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel

###
# We're using Lambda, but we need to install pshtt locally because the
# pshtt.py and sslyze.py files in the scanners directory of
# 18F/domain-scan import pshtt and sslyze, respectively, at the top of
# the file.  (trustymail imports only in the scan function, so it
# isn't required here.)
###
RUN pip3 install --no-cache-dir --upgrade pshtt==0.6.10

###
# Install domain-scan
#
# The SHELL command is used to ensure that if either the curl call or
# the tar call fail then the image build fails. Source:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#using-pipes
###
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir ${CISA_HOME}/domain-scan \
    && curl --location https://github.com/cisagov/domain-scan/tarball/master \
    | tar --extract --gzip --strip-components 1 --directory ${CISA_HOME}/domain-scan/
RUN pip3 install --no-cache-dir --upgrade \
    --requirement ${CISA_HOME}/domain-scan/requirements.txt

###
# Remove install dependencies
###
RUN apt-get remove --quiet --quiet $INSTALL_DEPS

###
# Clean up aptitude cruft
###
RUN apt-get --quiet --quiet clean
RUN rm -rf /var/lib/apt/lists/*

###
# Setup working directory and entrypoint
###

# Put this just before we change users because the copy (and every
# step after it) will always be rerun by Docker, but we need to be
# root for the chown command.
COPY src/scan.sh ${CISA_HOME}
RUN chown -R ${CISA_USER}:${CISA_GROUP} ${CISA_HOME}

###
# Prepare to run
###
# TODO: Right now we need to be root at runtime in order to create
# files in ${CISA_HOME}/shared, but see cisagov/orchestrator#130.
# USER ${CISA_USER}:${CISA_GROUP}
WORKDIR ${CISA_HOME}
ENTRYPOINT ["./scan.sh"]
