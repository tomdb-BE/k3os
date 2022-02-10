ARG REPO
ARG TAG

FROM ${REPO}/rke2os-package:${TAG} as package
FROM ${REPO}/rke2os-base:${TAG} as base
ARG ARCH
RUN apt-get install -y --no-install-recommends xorriso mtools libvirt0 qemu-utils
RUN if [ "$ARCH" = "amd64" ]; then \
        apt-get install -y --no-install-recommends qemu-system-x86 ovmf grub-efi; \
        ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-system; \
    elif [ "$ARCH" = "arm64" ]; then \
        apt-get install -y --no-install-recommends qemu-system-aarch64 grub-common; \
        ln -s /usr/bin/qemu-system--aarch64 /usr/bin/qemu-system; \
    fi
RUN qemu-img create -f qcow2 /hd.img 40G
COPY run-kvm.sh /usr/bin/
COPY grub.cfg /usr/src/iso/boot/grub/grub.cfg

COPY --from=package /output/ /usr/src/iso/

COPY config.yaml /usr/src/iso/rke2os/system/
RUN mkdir -p /output && \
    grub-mkrescue -o /output/rke2os.iso /usr/src/iso/. -- -volid RKE2OS -joliet on && \
    [ -e /output/rke2os.iso ] # grub-mkrescue doesn't exit non-zero on failure

CMD ["run-kvm.sh"]
