FROM ubuntu:16.04
MAINTAINER Shane Frasier <jeremy.frasier@trio.dhs.gov>

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

###
# Dependencies
###
RUN apt-get update -qq \
    && apt-get install -qq --yes --no-install-recommends --no-install-suggests \
    build-essential \
    curl \
    git \
    libc6-dev \
    libfontconfig1 \
    libreadline-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    make \
    unzip \
    wget \
    zlib1g-dev \
    autoconf \
    automake \
    bison \
    gawk \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libtool \
    pkg-config \
    sqlite3 \
    libgeos-dev \
    libbz2-dev \
    llvm \
    libncursesw5-dev \
    nodejs \
    npm \
    redis-tools

###
## Python
###
ENV PYENV_RELEASE=1.2.2 \
    PYENV_PYTHON_VERSION=3.6.4 \
    PYENV_ROOT=/opt/pyenv \
    PYENV_REPO=https://github.com/pyenv/pyenv

RUN wget ${PYENV_REPO}/archive/v${PYENV_RELEASE}.zip \
      --no-verbose \
    && unzip v$PYENV_RELEASE.zip -d $PYENV_ROOT \
    && mv $PYENV_ROOT/pyenv-$PYENV_RELEASE/* $PYENV_ROOT/ \
    && rm -r $PYENV_ROOT/pyenv-$PYENV_RELEASE

#
# Uncomment these lines if you just want to install python...
#
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/versions/${PYENV_PYTHON_VERSION}/bin:$PATH
RUN echo 'eval "$(pyenv init -)"' >> /etc/profile \
    && eval "$(pyenv init -)" \
    && pyenv install $PYENV_PYTHON_VERSION \
    && pyenv local ${PYENV_PYTHON_VERSION}

#
# ...uncomment these lines if you want to also debug python code in GDB
#
# ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/versions/${PYENV_PYTHON_VERSION}-debug/bin:$PATH
# RUN echo 'eval "$(pyenv init -)"' >> /etc/profile \
#     && eval "$(pyenv init -)" \
#     && pyenv install --debug --keep $PYENV_PYTHON_VERSION \
#     && pyenv local ${PYENV_PYTHON_VERSION}-debug
# RUN ln -s /opt/pyenv/sources/${PYENV_PYTHON_VERSION}-debug/Python-${PYENV_PYTHON_VERSION}/python-gdb.py \
#     /opt/pyenv/versions/${PYENV_PYTHON_VERSION}-debug/bin/python3.6-gdb.py \
#     && ln -s /opt/pyenv/sources/${PYENV_PYTHON_VERSION}-debug/Python-${PYENV_PYTHON_VERSION}/python-gdb.py \
#     /opt/pyenv/versions/${PYENV_PYTHON_VERSION}-debug/bin/python3-gdb.py \
#     && ln -s /opt/pyenv/sources/${PYENV_PYTHON_VERSION}-debug/Python-${PYENV_PYTHON_VERSION}/python-gdb.py \
#     /opt/pyenv/versions/${PYENV_PYTHON_VERSION}-debug/bin/python-gdb.py
# RUN apt-get -qq --yes --no-install-recommends --no-install-suggests install gdb
# RUN echo add-auto-load-safe-path \
#     /opt/pyenv/sources/${PYENV_PYTHON_VERSION}-debug/Python-${PYENV_PYTHON_VERSION}/ \
#     >> etc/gdb/gdbinit

##
# Make sure pip and setuptools are the latest versions
##
RUN pip install --upgrade pip setuptools

##
# We're using Lambda, but we need to install pshtt locally because the
# pshtt.py and sslyze.py files in the scanners directory of
# 18F/domain-scan import pshtt and sslyze, respectively, at the top of
# the file.  (trustymail imports only in the scan function, so it
# isn't required here.)
##
RUN pip install --upgrade pshtt==0.6.1

###
# Install domain-scan
###
RUN git clone https://github.com/18F/domain-scan /home/scanner/domain-scan/ \
    && pip install --upgrade -r /home/scanner/domain-scan/requirements.txt

###
# Create unprivileged user
###
ENV SCANNER_HOME=/home/scanner
RUN groupadd -r scanner \
    && useradd -r -c "Scanner user" -g scanner scanner

# It would be nice to get rid of some build dependencies at this point

# Clean up aptitude cruft
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Put this just before we change users because the copy (and every
# step after it) will always be rerun by docker, but we need to be
# root for the chown command.
COPY . $SCANNER_HOME
RUN chown -R scanner:scanner ${SCANNER_HOME}

###
# Prepare to Run
###
# Right now we need to be root at runtime in order to create files in
# /home/shared
# USER scanner:scanner
WORKDIR $SCANNER_HOME
ENTRYPOINT ["./scan.sh"]
