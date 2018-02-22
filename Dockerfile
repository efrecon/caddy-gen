#
# First Pass, build (makes plugins available)
FROM abiosoft/caddy:builder as builder

ARG CADDY_VERSION="0.10.11"
ARG CADDY_PLUGINS="git"

RUN VERSION=${CADDY_VERSION} PLUGINS=${CADDY_PLUGINS} /bin/sh /usr/bin/builder.sh

#
# Second pass, restart from minimal image and add necessary binaries.
FROM alpine:3.7

LABEL maintainer="Nikita Sobolev <sobolevn@wemake.services>"
LABEL CADDY_VERSION="0.10.11"

COPY --from=builder /install/caddy /usr/bin/caddy

ARG FOREGO_VERSION="0.16.1"
ARG DOCKER_GEN_VERSION="0.7.3"

ENV CADDYPATH="/etc/caddy"
ENV DOCKER_HOST unix:///tmp/docker.sock


# Install wget and install/updates certificates

RUN apk update && apk upgrade \
  && apk add --no-cache bash openssh-client git \
  && apk add --no-cache --virtual .build-dependencies curl wget tar


# Install Forego

 RUN wget --quiet "https://github.com/jwilder/forego/releases/download/v${FOREGO_VERSION}/forego" \
  && mv ./forego /usr/bin/forego \
  && chmod u+x /usr/bin/forego


# Install docker-gen

RUN wget --quiet "https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz" \
  && tar -C /usr/bin -xvzf "docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz" \
  && rm "/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz" \
  && apk del .build-dependencies

# validate caddy install

RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /etc/caddy


# Starting app:

ADD . /code
WORKDIR /code

ENTRYPOINT ["sh", "/code/docker-entrypoint.sh"]
CMD ["/usr/bin/forego", "start", "-r"]
