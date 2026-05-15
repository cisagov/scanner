# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/library/python:3.14.5-slim-bookworm AS compile-stage

###
# Unprivileged user variables
###
ARG CISA_USER="cisa"
ENV CISA_HOME="/home/${CISA_USER}"
ENV VIRTUAL_ENV="${CISA_HOME}/.venv"

# Versions of the Python packages installed directly
ENV PYTHON_PIP_VERSION=24.0
# This is the latest version of pipenv available for Python 3.7.17.
ENV PYTHON_PIPENV_VERSION=2023.10.3
ENV PYTHON_SETUPTOOLS_VERSION=68.0.0

###
# Install the specified versions of pip and setuptools into the system
# Python environment; install the specified version of pipenv into the system Python
# environment; set up a Python virtual environment (venv); and install the specified
# versions of pip and setuptools into the venv.
#
# Note that we use the --no-cache-dir flag to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN python3 -m pip install --no-cache-dir --upgrade \
        pip==${PYTHON_PIP_VERSION} \
        setuptools==${PYTHON_SETUPTOOLS_VERSION} \
    && python3 -m pip install --no-cache-dir --upgrade \
        pipenv==${PYTHON_PIPENV_VERSION} \
    # Manually create the virtual environment
    && python3 -m venv ${VIRTUAL_ENV} \
    # Ensure the core Python packages are installed in the virtual environment
    && ${VIRTUAL_ENV}/bin/python3 -m pip install --no-cache-dir --upgrade \
        pip==${PYTHON_PIP_VERSION} \
        setuptools==${PYTHON_SETUPTOOLS_VERSION}

###
# Check the Pipfile configuration and then install the Python dependencies into
# the virtual environment.
#
# Note that pipenv will install into a virtual environment if the VIRTUAL_ENV
# environment variable is set.
###
WORKDIR /tmp
COPY src/Pipfile src/Pipfile.lock ./
RUN pipenv install --clear --deploy --extra-pip-args "--no-cache-dir" --verbose

###
# Install domain-scan
#
# The SHELL command is used to ensure that if either the curl call or
# the tar call fail then the image build fails. Source:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#using-pipes
###
RUN apt update --quiet --quiet \
    && apt install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
    curl
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN mkdir ${CISA_HOME}/domain-scan \
  && curl --location https://github.com/cisagov/domain-scan/tarball/master \
  | tar --extract --gzip --strip-components 1 --directory ${CISA_HOME}/domain-scan/
# We can't use --deploy with --requirements
RUN pipenv install --clear --extra-pip-args "--no-cache-dir" --verbose \
  --requirements ${CISA_HOME}/domain-scan/requirements.txt

# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/library/python:3.14.5-slim-bookworm AS build-stage

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
LABEL org.opencontainers.image.authors="vm-dev@gwe.cisa.dhs.gov"
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
ENV VIRTUAL_ENV="${CISA_HOME}/.venv"

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
RUN apt update
RUN apt install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
    bash \
    redis-tools

###
# Copy in the Python virtual environment created in compile-stage, symlink the
# Python binary in the venv to the system-wide Python, and add the venv to the PATH.
#
# Note that we symlink the Python binary in the venv to the system-wide Python so that
# any calls to `python3` will use our virtual environment. We are using short flags
# because the ln binary in Alpine Linux does not support long flags. The -f instructs
# ln to remove the existing file and the -s instructs ln to create a symbolic link.
###
COPY --from=compile-stage --chown=${CISA_USER}:${CISA_GROUP} ${VIRTUAL_ENV} ${VIRTUAL_ENV}
RUN ln -fs "$(command -v python3)" "${VIRTUAL_ENV}"/bin/python3
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

# Copy in our domain-scan checkout
COPY --from=compile-stage --chown=${CISA_USER}:${CISA_GROUP} ${CISA_HOME}/domain-scan ${CISA_HOME}/domain-scan

###
# Clean up aptitude cruft
###
RUN apt clean --quiet --quiet
RUN rm -rf /var/lib/apt/lists/*

###
# Setup working directory and entrypoint
###

# Put this just before we change users because the copy (and every
# step after it) will always be rerun by Docker, but we need to be
# root for the chown command.
COPY --chown=${CISA_USER}:${CISA_GROUP} src/scan.sh ${CISA_HOME}

###
# Prepare to run
###
# TODO: Right now we need to be root at runtime in order to create
# files in ${CISA_HOME}/shared, but see cisagov/orchestrator#130.
# USER ${CISA_USER}:${CISA_GROUP}
WORKDIR ${CISA_HOME}
ENTRYPOINT ["./scan.sh"]
