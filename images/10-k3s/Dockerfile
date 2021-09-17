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
RUN tar zxvf rke2.linux-${ARCH}.tar.gz  && \
    mkdir /output                       && \
    mv bin/rke2 /output/k3s             && \
    mv bin/* /output/                   && \
    echo ${RKE2_VERSION} > /output/version
ENV INSTALL_RKE2_VERSION=${RKE2_VERSION} \
    INSTALL_RKE2_TAR_PREFIX=/output
