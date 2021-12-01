ARG REPO
ARG TAG
FROM ${REPO}/rke2os-rootfs:${TAG} as rootfs

ARG REPO
ARG TAG
FROM ${REPO}/rke2os-progs:${TAG} as progs

ARG REPO
ARG TAG
FROM ${REPO}/rke2os-base:${TAG}

COPY --from=rootfs /output/rootfs.squashfs /usr/src/
COPY install.sh /output/rke2os-install.sh
COPY --from=progs /output/rke2os /output/rke2os
RUN echo -n "_sqmagic_" >> /output/rke2os
RUN cat /usr/src/rootfs.squashfs >> /output/rke2os
