ARG REPO
ARG TAG
FROM ${REPO}/k3os-k3s:${TAG} as k3s

ARG REPO
ARG TAG
FROM ${REPO}/k3os-bin:${TAG} as bin

ARG REPO
ARG TAG
FROM ${REPO}/k3os-base:${TAG} as base
ARG VERSION

COPY --from=k3s /output/  /output/k3os/system/rke2/
COPY --from=bin /output/  /output/k3os/system/k3os/${VERSION}/

WORKDIR /output/k3os/system/rke2
RUN mkdir -vp $(cat version) /output/sbin
RUN ln -sf $(cat version) current
RUN mv -vf install.sh current/rke2-install.sh
RUN ln -sf rke2-install.sh current/k3s-install.sh
RUN mv -vf rke2 current/
RUN mv -vf rke2-killall-sh current/
RUN rm -vf version *.sh
RUN ln -sf /k3os/system/rke2/current/rke2 /output/sbin/rke2
RUN ln -sf /k3os/system/rke2/current/rke2 /output/sbin/k3s

WORKDIR /output/k3os/system/k3os
RUN ln -sf ${VERSION} current
RUN ln -sf /k3os/system/k3os/current/k3os /output/sbin/k3os
RUN ln -sf k3os /output/sbin/init
