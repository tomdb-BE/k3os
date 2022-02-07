ARG REPO
ARG TAG

FROM ${REPO}/rke2os-base:${TAG}
ARG RKE2_VERSION
ARG ARCH
ARG GITREPO
ENV ARCH=${ARCH}                         \
    RKE2_VERSION=${RKE2_VERSION}         \
    GITREPO=${GITREPO}                   \
    INSTALL_RKE2_VERSION=${RKE2_VERSION} \
    INSTALL_RKE2_NAME=service            \
    INSTALL_RKE2_SKIP_START=true         \
    INSTALL_RKE2_SKIP_ENABLE=true        \
    INSTALL_RKE2_TAR_PREFIX=/output
ADD ./rke2openrc.sh ./
RUN mkdir /output                                                                                                           \
 && curl -sO https://raw.githubusercontent.com/${GITREPO}/rke2/$(echo "${RKE2_VERSION}" | sed -r 's/\+/\%2B/g')/install.sh  \
 && sed -i '/systemd/d' install.sh                                                                                          \
 && sed -i '/systemctl/d' install.sh                                                                                        \
 && sed -i 's/github\.com\/rancher\//github\.com\/${GITREPO}\//' install.sh                                                 \
 && sed -i 's/setup_arch$/SUFFIX=linux-${ARCH}\n\ \ \ \ ARCH=${ARCH}/g' install.sh                                          \
 && head -n -2 install.sh > /output/install.sh                                                                              \
 && cat rke2openrc.sh >> /output/install.sh                                                                                 \
 && chmod +x /output/install.sh                                                                                             \
 && /output/install.sh                                                                                                      \
 && rm -f /output/rke2.exe                                                                                                  \
 && echo "${RKE2_VERSION}" > /output/version
