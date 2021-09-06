ARG REPO
ARG TAG
ARG VERSION
ARG RKE2_VERSION
ARG ARCH
FROM ${REPO}/rke2-runtime:${RKE2_VERSION}-linux-${ARCH} AS runtime
FROM ${REPO}/k3os-base:${TAG}

ARG ARCH
ARG K3S_VERSION=v1.21.4+k3s1
ENV ARCH ${ARCH}
ENV VERSION ${K3S_VERSION}
ADD https://raw.githubusercontent.com/rancher/k3s/${K3S_VERSION}/install.sh /output/install.sh
ENV INSTALL_K3S_VERSION=${K3S_VERSION} \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_BIN_DIR=/output
RUN chmod +x /output/install.sh
RUN /output/install.sh
COPY --from=runtime /bin/crictl /output/crictl
COPY --from=runtime /bin/kubectl /output/kubectl
COPY --from=runtime /bin/ctr /output/ctr
ADD ./rke2 /output/k3s
RUN echo "${VERSION}" > /output/version
