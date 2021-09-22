ARG REPO
ARG TAG
ARG RKE2_VERSION
ARG ARCH

FROM ${REPO}/rke2-runtime:${RKE2_VERSION}-linux-${ARCH} AS runtime

FROM ${REPO}/k3os-base:${TAG}
ARG K3S_VERSION
ARG RKE2_VERSION
ARG ARCH
ARG GITREPO
ENV VERSION=${K3S_VERSION}
ENV GTIREPO=${GITREPO}
ADD https://github.com/${GITREPO}/rke2/releases/download/${RKE2_VERSION}/rke2.linux-${ARCH}.tar.gz ./
ADD https://raw.githubusercontent.com/tomdb-BE/rke2/${RKE2_VERSION}/install.sh ./
RUN sed -i '/systemd/d' ./install.sh
RUN sed -i '/systemctl/d' ./install.sh
RUN sed -i "s/github\.com\/rancher\//github\.com\/${GITREPO}\//" ./install.sh
RUN sed -i "s/setup_arch$/SUFFIX=linux-${ARCH}\n\ \ \ \ ARCH=${ARCH}/g" ./install.sh
RUN sha256sum rke2.linux-${ARCH}.tar.gz > sha256sum-${ARCH}.txt
ENV INSTALL_RKE2_VERSION=${RKE2_VERSION}
RUN chmod +x install.sh
RUN ./install.sh
RUN mkdir /output
RUN echo "${RKE2_VERSION}" > /output/version
RUN mv /usr/local/bin/rke2 /output/
RUN mv /usr/local/bin/rke2-killall.sh /output/
RUN mv ./install.sh /output/rke2-install.sh
ADD https://raw.githubusercontent.com/rancher/k3s/${VERSION}/install.sh /output/install.sh
ENV INSTALL_K3S_VERSION=${VERSION} \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_BIN_DIR=/output
RUN chmod +x /output/install.sh
RUN /output/install.sh
