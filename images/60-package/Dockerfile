ARG REPO
ARG TAG
FROM ${REPO}/rke2os-kernel:${TAG} as kernel

ARG REPO
ARG TAG
FROM ${REPO}/rke2os-package:${TAG}
ARG VERSION

COPY --from=kernel /output/ /output/rke2os/system/kernel/

WORKDIR /output/rke2os/system/kernel
RUN mkdir -vp $(cat version)
RUN ln -sf $(cat version) current
RUN mv -vf initrd kernel.squashfs current/
RUN rm -vf version vmlinuz
