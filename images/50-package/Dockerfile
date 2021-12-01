ARG REPO
ARG TAG
FROM ${REPO}/rke2os-k3s:${TAG} as rke2

ARG REPO
ARG TAG
FROM ${REPO}/rke2os-bin:${TAG} as bin

ARG REPO
ARG TAG
FROM ${REPO}/rke2os-base:${TAG} as base
ARG VERSION

COPY --from=rke2 /output/  /output/rke2os/system/rke2/
COPY --from=bin /output/  /output/rke2os/system/rke2os/${VERSION}/

WORKDIR /output/rke2os/system/rke2
RUN mkdir -vp $(cat version) /output/sbin
RUN ln -sf $(cat version) current
RUN mv -vf rke2-install.sh current/
RUN mv -vf rke2-killall.sh current/
RUN mv -vf rke2 current/
RUN rm -vf version *.sh
RUN ln -sf /rke2os/system/rke2/current/rke2 /output/sbin/rke2

WORKDIR /output/rke2os/system/rke2os
RUN ln -sf ${VERSION} current
RUN ln -sf /rke2os/system/rke2os/current/rke2os /output/sbin/rke2os
RUN ln -sf rke2os /output/sbin/init
