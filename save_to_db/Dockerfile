FROM python:3.6.3-alpine3.6
MAINTAINER Shane Frasier <jeremy.frasier@beta.dhs.gov>
###
# Install shadow, so we have adduser and addgroup.  We can remove the
# package once we're finished with it.
###
RUN apk update && \
    apk add shadow

###
# Dependencies
###
RUN pip3 install pymongo pytz pyyaml

###
# Create unprivileged user
###
ENV SCANNER_HOME=/home/scanner
RUN addgroup -S scanner \
    && adduser -S -g "Scanner user" -G scanner scanner

# Remove build dependencies
RUN apk del shadow

# Put this just before we change users because the copy (and every
# step after it) will always be rerun by docker, but we need to be
# root for the chown command.
COPY . $SCANNER_HOME
RUN chown -R scanner:scanner ${SCANNER_HOME}

###
# Prepare to Run
###
# Right now we need to be root to create the file that
# tells the report container to grab the data from the database.
# USER scanner:scanner
WORKDIR $SCANNER_HOME
ENTRYPOINT ["./save_to_db.sh"]
