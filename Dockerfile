FROM golang:1.14-alpine AS buildenv

ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev
ENV VERSION v2.0.11

# Set up dependencies
RUN apk add --update --no-cache $PACKAGES

# Set working directory for the build
WORKDIR /go/src/github.com/cosmos/

# Add source files
RUN git clone --recursive https://www.github.com/cosmos/gaia
WORKDIR /go/src/github.com/cosmos/gaia

RUN git checkout $VERSION

# Install minimum necessary dependencies, build Cosmos SDK, remove packages
RUN make install

# ------------------------------------------------------------------ #

FROM alpine:edge

ENV GAIAD_HOME=/.gaiad

# Install ca-certificates
RUN apk add --no-cache --update ca-certificates supervisor wget lz4

# Temp directory for copying binaries
RUN mkdir -p /tmp/bin
WORKDIR /tmp/bin

COPY --from=buildenv /go/bin/gaiad /tmp/bin
COPY --from=buildenv /go/bin/gaiacli /tmp/bin
RUN install -m 0755 -o root -g root -t /usr/local/bin gaiad
RUN install -m 0755 -o root -g root -t /usr/local/bin gaiacli

# Remove temp files
RUN rm -r /tmp/bin

# Add supervisor configuration files
RUN mkdir -p /etc/supervisor/conf.d/
COPY /supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY /supervisor/conf.d/* /etc/supervisor/conf.d/


WORKDIR $GAIAD_HOME

ENV MONIKER=Bitrue
ENV CHAIN_ID=cosmoshub-3
ENV BOOTSTRAP=TRUE
ENV SEEDS='ba3bacc714817218562f743178228f23678b2873@5.83.160.108:26656,1e63e84945837b026f596ed8ae68708783d04ad4@51.75.145.123:26656,d2d452e7c9c43fa5ef017552688de60a5c0053ee@34.245.217.163:26656,dd36969b56c740bb40bb8badd4d4c6facc35dc24@206.189.115.41:26656,a0aca8fb801c69653a290bd44872e8457f8b0982@47.99.180.54:26656,27f8dd3bdbecbef7192291083706c156e523d8e0@3.122.248.21:26656,aee0df1a660f301d456a0c2f805b372f7341e8ec@63.35.230.143:26656,7d1f660b361d6286715c098a3a171e554e9642bb@34.254.205.37:26656,fa105c2291ac4aa452552fa4835266300a8209e1@88.198.41.62:26656,bd410d4564f7e0dd9a0eb16a64c337a059e11b80@47.103.35.130:26656'
ENV PROMETHEUS=true

# Expose ports for gaiad and gaiacli rest-server
EXPOSE 26656 26657 26658
EXPOSE 1317

# Add entrypoint script
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod u+x /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

STOPSIGNAL SIGINT
