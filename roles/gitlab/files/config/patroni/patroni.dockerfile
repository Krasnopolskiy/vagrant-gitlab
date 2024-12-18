FROM postgres:17

RUN mkdir -p /data/patroni \
    && chown postgres:postgres /data/patroni \
    && chmod 700 /data/patroni

RUN apt update && apt install -y python3 python3-pip

RUN pip3 install --upgrade --break-system-packages \
    setuptools \
    psycopg2-binary \
    patroni[consul]

RUN chown -R postgres:postgres /data

USER postgres
