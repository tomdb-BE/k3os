ARG REPO
ARG TAG
ARG RKE2_VERSION
ARG ARCH

FROM ${REPO}/rke2-runtime:${RKE2_VERSION}-linux-${ARCH} AS runtime

FROM ${REPO}/k3os-base:${TAG}
ARG RKE2_VERSION
ARG ARCH
ENV VERSION=${RKE2_VERSION}
ADD https://github.com/tomdb-BE/rke2/releases/download/${RKE2_VERSION}/rke2.linux-${ARCH}.tar.gz ./
ADD https://raw.githubusercontent.com/tomdb-BE/rke2/${RKE2_VERSION}/install.sh /output/install.sh
RUN sha256sum rke2.linux-${ARCH}.tar.gz > sha256sum-${ARCH}.txt
ENV INSTALL_RKE2_VERSION=${RKE2_VERSION} \
    INSTALL_RKE2_TAR_PREFIX=/output \
    INSTALL_RKE2_ARTIFACT_PATH=./
RUN chmod +x /output/install.sh
RUN mkdir -p /etc/systemd/system
RUN echo "sleep 1" > /bin/systemctl
RUN chmod +x /bin/systemctl
RUN /output/install.sh
RUN echo "${RKE2_VERSION}" > /output/version
RUN mv /output/bin/rke2 /output/k3s
