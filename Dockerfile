FROM debian:bookworm-slim AS builder
LABEL maintainer="rev1si0n <lamda.devel@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV OPENRESTY=/usr/local/openresty
ENV MIRROR=mirrors.tuna.tsinghua.edu.cn
ENV HOME=/user

# ── base system: cached unless build-base.sh or patch changes (~208s) ───────
COPY pip.conf                  /etc
COPY build-base.sh             /tmp/build/build-base.sh
COPY mosquitto-auth-plug.patch /tmp/build/mosquitto-auth-plug.patch

RUN bash /tmp/build/build-base.sh

# ── desktop: cached unless build-desk.sh changes (~363s) ────────────────────
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=C
ENV DISPLAY_WIDTH=1600
ENV DISPLAY_HEIGH=900
ENV DISPLAY=:4096

COPY build-desk.sh             /tmp/build/build-desk.sh

RUN bash /tmp/build/build-desk.sh

# ── main service: rebuilds only when Python sources change (~176s) ───────────
ADD . /tmp/build

COPY nginx.conf         ${OPENRESTY}/nginx/conf
COPY redis.conf         /etc
COPY account.py         /usr/bin
COPY entry              /usr/bin

RUN bash /tmp/build/build-main.sh

RUN cd ~ && ls -A1 | xargs rm -rf ; \
    cd /tmp && ls -A1 | xargs rm -rf ; \
    cd /root && ls -A1 | xargs rm -rf ; \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8000 65000
WORKDIR                 /user
CMD [ "entry" ]
