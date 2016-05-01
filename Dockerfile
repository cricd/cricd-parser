FROM alpine:latest

MAINTAINER Ryan Scott <ryankennethscott@gmail.com>


ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base curl wget bash git openssh ca-certificates
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler


RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cached/apk*

RUN git clone https://github.com/ryankscott/cricket_tools.git
RUN cd cricket_tools && bundle install
