ARG REPO
ARG TAG
FROM ${REPO}/rke2os-tar:${TAG} as tar
FROM ${REPO}/rke2os-iso:${TAG} as iso
FROM ${REPO}/rke2os-kernel:${TAG} as kernel
FROM ${REPO}/rke2os-base:${TAG}
ARG ARCH

COPY --from=kernel /output/vmlinuz /output/rke2os-vmlinuz-${ARCH}
COPY --from=kernel /output/initrd /output/rke2os-initrd-${ARCH}
COPY --from=kernel /output/kernel.squashfs /output/rke2os-kernel-${ARCH}.squashfs
COPY --from=kernel /output/version /output/rke2os-kernel-version-${ARCH}
COPY --from=iso /output/rke2os.iso /output/rke2os-${ARCH}.iso
COPY --from=tar /output/userspace.tar /output/rke2os-rootfs-${ARCH}.tar
RUN gzip /output/rke2os-rootfs-${ARCH}.tar
