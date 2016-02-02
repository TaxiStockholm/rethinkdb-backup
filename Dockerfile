FROM ubuntu:trusty
# Add the RethinkDB repository and public key
# "RethinkDB Packaging <packaging@rethinkdb.com>" http://download.rethinkdb.com/apt/pubkey.gpg
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 1614552E5765227AEC39EFCFA7E00EF33A8F2399
RUN echo "deb http://download.rethinkdb.com/apt trusty main" > /etc/apt/sources.list.d/rethinkdb.list
RUN apt-get update --fix-missing \
  && apt-get -y install python-pip \
  && apt-get install -y rethinkdb \
  && rm -rf /var/lib/apt/lists/* \
  && sudo pip install rethinkdb \
  && mkdir /backups \
  && mkdir /scripts

ENV CRON_TIME="0 0 * * *"

ADD run.sh /run.sh

VOLUME ["/backups"]

CMD ["/run.sh"]
