ARG REPO
ARG TAG
FROM ${REPO}/rke2os-tar:${TAG} as tar
FROM ${REPO}/rke2os-base:${TAG}
ARG ARCH

COPY --from=tar /output/userspace.tar /output/rke2os-rootfs-${ARCH}.tar
RUN gzip /output/rke2os-rootfs-${ARCH}.tar
