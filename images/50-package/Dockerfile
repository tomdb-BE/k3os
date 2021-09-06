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

COPY --from=k3s /output/  /output/k3os/system/k3s/
COPY --from=bin /output/  /output/k3os/system/k3os/${VERSION}/

WORKDIR /output/k3os/system/k3s
RUN mkdir -vp $(cat version) /output/sbin
RUN mv -vf crictl ctr kubectl /output/sbin/$(cat version)
RUN ln -sf $(cat version) current
RUN mv -vf install.sh current/k3s-install.sh
RUN mv -vf k3s current/
RUN rm -vf version *.sh
RUN ln -sf /k3os/system/k3s/current/k3s /output/sbin/k3s

WORKDIR /output/k3os/system/k3os
RUN ln -sf ${VERSION} current
RUN ln -sf /k3os/system/k3os/current/k3os /output/sbin/k3os
RUN ln -sf k3os /output/sbin/init
RUN echo 'k3s_args:' >> config.yaml                                           && \
    echo '"--data-dir /var/lib/rancher/k3s"' >> config.yaml                   && \
    echo '"--write-kubeconfig /var/lib/rancher/k3s/k3s.yaml"' >> config.yaml
