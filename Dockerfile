FROM docker:17.03.2-dind

RUN apk add --no-cache curl git openssh-client jq

COPY build.sh /build.sh

ENV RESIN_REGISTRY=registry.resin.io TARGET_IMAGE_TAG=latest

CMD ["/build.sh"]
