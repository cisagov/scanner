###
# Install everything we need
###
FROM python:3.6-slim-buster AS install
LABEL maintainer="jeremy.frasier@trio.dhs.gov"
LABEL organization="CISA Cyber Assessments"
LABEL url="https://github.com/cisagov/scanner"

ENV HOME=/home/scanner

###
# Dependencies
#
# Install dependencies are only needed for software installation and
# will be removed at the end of the build process.
###
ENV DEPS \
    bash \
    redis-tools
ENV INSTALL_DEPS \
    curl \
    git
RUN apt-get update --quiet --quiet
RUN apt-get upgrade --quiet --quiet
RUN apt-get install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
    $DEPS $INSTALL_DEPS

###
# Make sure pip and setuptools are the latest versions
###
RUN pip install --no-cache-dir --upgrade pip setuptools

###
# We're using Lambda, but we need to install pshtt locally because the
# pshtt.py and sslyze.py files in the scanners directory of
# 18F/domain-scan import pshtt and sslyze, respectively, at the top of
# the file.  (trustymail imports only in the scan function, so it
# isn't required here.)
###
RUN pip install --no-cache-dir --upgrade pshtt==0.6.6

###
# Install domain-scan
###
RUN git clone https://github.com/18F/domain-scan \
    ${HOME}/domain-scan/
RUN pip install --no-cache-dir --upgrade \
    --requirement ${HOME}/domain-scan/requirements.txt

###
# Remove build dependencies
###
RUN apt-get remove --quiet --quiet $BUILD_DEPS

###
# Clean up aptitude cruft
###
RUN apt-get --quiet --quiet clean
RUN rm -rf /var/lib/apt/lists/*


###
# Setup the scanner user and its home directory
###
FROM install AS setup_user

###
# Create unprivileged user
###
RUN groupadd -r scanner
RUN useradd -r -c "Scanner user" -g scanner scanner

# Put this just before we change users because the copy (and every
# step after it) will always be rerun by docker, but we need to be
# root for the chown command.
COPY . $HOME
RUN chown -R scanner:scanner $HOME


###
# Setup working directory and entrypoint
###
FROM setup_user AS final

###
# Prepare to Run
###
# Right now we need to be root at runtime in order to create files in
# /home/shared
# USER scanner:scanner
WORKDIR $HOME
ENTRYPOINT ["./scan.sh"]
