ARG REPO
ARG TAG

FROM ${REPO}/k3os-base:${TAG}
ARG K3S_VERSION
ARG RKE2_VERSION
ARG ARCH
ARG GITREPO
ENV ARCH=${ARCH}                         \
    K3S_VERSION=${K3S_VERSION}           \
    RKE2_VERSION=${RKE2_VERSION}         \
    GITREPO=${GITREPO}                   \
    INSTALL_RKE2_VERSION=${RKE2_VERSION} \
    INSTALL_RKE2_SKIP_START=true         \
    INSTALL_K3S_VERSION=${K3S_VERSION}   \
    INSTALL_K3S_SKIP_START=true          \
    INSTALL_K3S_BIN_DIR=/output
WORKDIR /rke2build
RUN mkdir /output                                                                                                 && \
    curl -sO https://github.com/${GITREPO}/rke2/releases/download/${RKE2_VERSION/+/%2B}/rke2.linux-${ARCH}.tar.gz && \
    curl -sO https://raw.githubusercontent.com/${GITREPO}/rke2/${RKE2_VERSION/+/%2B}/install.sh                   && \
    curl -s -o /output/install.sh https://raw.githubusercontent.com/rancher/k3s/${K3S_VERSION}/install.sh         && \
    sed -i '/systemd/d' ./install.sh                                                                              && \
    sed -i '/systemctl/d' ./install.sh                                                                            && \
    sed -i "s/github\.com\/rancher\//github\.com\/${GITREPO}\//" ./install.sh                                     && \
    sed -i "s/setup_arch$/SUFFIX=linux-${ARCH}\n\ \ \ \ ARCH=${ARCH}/g" ./install.sh                              && \
    sha256sum rke2.linux-${ARCH}.tar.gz > sha256sum-${ARCH}.txt                                                   && \
    chmod +x install.sh                                                                                           && \
    ./install.sh                                                                                                  && \
    echo "${RKE2_VERSION}" > /output/version                                                                      && \
    mv /usr/local/bin/rke2 /output/                                                                               && \
    mv /usr/local/bin/rke2-killall.sh /output/                                                                    && \
    mv ./install.sh /output/rke2-install.sh                                                                       && \
    chmod +x /output/install.sh                                                                                   && \
    /output/install.sh
