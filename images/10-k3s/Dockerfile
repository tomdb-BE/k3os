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
    INSTALL_RKE2_TAR_PREFIX=/output
ADD ./rke2openrc.sh ./
RUN mkdir /output                                                                                           \
 && curl -s -o /output/ https://raw.githubusercontent.com/${GITREPO}/rke2/${RKE2_VERSION/+/%2B}/install.sh  \
 && sed -i '/systemd/d' ./install.sh                                                                        \
 && sed -i '/systemctl/d' ./install.sh                                                                      \
 && sed -i "s/github\.com\/rancher\//github\.com\/${GITREPO}\//" ./install.sh                               \
 && sed -i "s/setup_arch$/SUFFIX=linux-${ARCH}\n\ \ \ \ ARCH=${ARCH}/g" ./install.sh                        \
 && head -n -2 ./install.sh                                                                                 \
 && cat ./rke2openrc.sh >> /install.sh                                                                      \
 && chmod +x install.sh                                                                                     \
 && /output/install.sh                                                                                      \
 && echo "${RKE2_VERSION}" > /output/version
