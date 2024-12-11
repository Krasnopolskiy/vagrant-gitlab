FROM haproxy:3.0

ENV CONSUL_TEMPLATE_VERSION=0.39.1

USER root

RUN apt update && apt install -y unzip curl

ADD https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_arm.zip /tmp/consul-template.zip

RUN unzip /tmp/consul-template.zip -d /usr/local/bin

RUN chown -R haproxy:haproxy /usr/local/etc/haproxy

USER haproxy
