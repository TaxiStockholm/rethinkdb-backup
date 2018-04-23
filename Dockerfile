FROM ubuntu:trusty

RUN echo "deb http://download.rethinkdb.com/apt trusty main" | tee /etc/apt/sources.list.d/rethinkdb.list

RUN apt-get update --fix-missing
RUN apt-get -y install wget

RUN wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | apt-key add -

RUN apt-get update --fix-missing
RUN apt-get -y install python-pip
RUN apt-get install -y rethinkdb
RUN rm -rf /var/lib/apt/lists/*
RUN pip install rethinkdb==2.2.0.post6

RUN mkdir /backups

ENV CRON_TIME="0 0 * * *"

VOLUME ["/backups"]

ADD ./scripts/run.sh /run.sh
ADD ./scripts/backup.sh /backup.sh
ADD ./scripts/restore.sh /restore.sh

CMD ["/run.sh"]
