FROM ubuntu:trusty
# Add the RethinkDB repository and public key
# "RethinkDB Packaging <packaging@rethinkdb.com>" http://download.rethinkdb.com/apt/pubkey.gpg
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 1614552E5765227AEC39EFCFA7E00EF33A8F2399
RUN echo "deb http://download.rethinkdb.com/apt trusty main" > /etc/apt/sources.list.d/rethinkdb.list
ENV RETHINKDB_PACKAGE_VERSION 1.13.0-0ubuntu1~trusty
RUN apt-get update \
  && apt-get -y install python-pip \
  && apt-get install -y rethinkdb=$RETHINKDB_PACKAGE_VERSION \
  && rm -rf /var/lib/apt/lists/* \
  && pip install rethinkdb \
  && mkdir /backup

ENV CRON_TIME="0 0 * * *" \
    RETHINKDB_DB="test"

ADD run.sh /run.sh

VOLUME ["/backup"]

CMD ["/run.sh"]
