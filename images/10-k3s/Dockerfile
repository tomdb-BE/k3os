ARG REPO
ARG TAG
ARG RKE2_VERSION
ARG ARCH

FROM ${REPO}/rke2-runtime:${RKE2_VERSION}-linux-${ARCH} AS runtime

FROM ${REPO}/k3os-base:${TAG}
ARG RKE2_VERSION
ARG ARCH
ARG GITREPO
ENV VERSION=${RKE2_VERSION}
ENV GTIREPO=${GITREPO}
ADD https://github.com/${GITREPO}/rke2/releases/download/${RKE2_VERSION}/rke2.linux-${ARCH}.tar.gz ./
ADD https://raw.githubusercontent.com/tomdb-BE/rke2/${RKE2_VERSION}/install.sh ./
RUN sed -i '/systemd/d' ./install.sh
RUN sed -i '/systemctl/d' ./install.sh
RUN sed -i "s/github\.com\/rancher\//github\.com\/${GITREPO}\//" install.sh
RUN sha256sum rke2.linux-${ARCH}.tar.gz > sha256sum-${ARCH}.txt
ENV INSTALL_RKE2_VERSION=${RKE2_VERSION}
RUN chmod +x install.sh
RUN ./install.sh
RUN echo "${RKE2_VERSION}" > /output/version
RUN mv ./bin/rke2 /output/
RUN mv ./bin/rke2-killall.sh /output/
run mv ./install.sh /output/
