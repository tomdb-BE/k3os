ARG REPO
ARG TAG

FROM ${REPO}/rke2os-base:${TAG} as base
FROM ${REPO}/rke2os-progs:${TAG} as progs
FROM ${REPO}/rke2os-rke2:${TAG} as rke2

FROM base as rke2os-build
ARG VERSION
ARG ARCH
RUN apt-get install -y --no-install-recommends squashfs-tools
COPY --from=base /bin /usr/src/image/bin/
COPY --from=base /lib /usr/src/image/lib/
COPY --from=base /sbin /usr/src/image/sbin/
COPY --from=base /etc /usr/src/image/etc/
COPY --from=base /usr /usr/src/image/usr/

# Fix up more stuff to move everything to /usr
RUN cd /usr/src/image && \
    for i in usr/*; do \
        if [ -e $(basename $i) ]; then \
            tar cvf - $(basename $i) | tar xvf - -C usr && \
            rm -rf $(basename $i) \
        ;fi && \
        mv $i . \
   ;done && \
   rmdir usr

# Fix coreutils links
RUN cd /usr/src/image/bin \
 && find -xtype l -ilname ../usr/bin/coreutils -exec ln -sf coreutils {} \;

# Fix sudo
RUN chmod +s /usr/src/image/bin/sudo

# Add empty dirs to bind mount
RUN mkdir -p /usr/src/image/lib/modules
RUN mkdir -p /usr/src/image/lib/firmware
RUN mkdir -p /usr/src/image/src

# setup /etc/ssl
RUN rm -rf \
    /usr/src/image/etc/ssl \
 && mkdir -p /usr/src/image/etc/ssl/certs/ \
 && cp -rf /etc/ssl/certs/ca-certificates.crt /usr/src/image/etc/ssl/certs \
 && ln -s certs/ca-certificates.crt /usr/src/image/etc/ssl/cert.pem

# setup /usr/local
RUN rm -rf /usr/src/image/local \
 && ln -s /var/local /usr/src/image/local

# setup /usr/libexec/kubernetes
RUN rm -rf /usr/libexec/kubernetes \
 && mkdir /usr/src/image/libexec \
 && ln -s /var/lib/rancher/rke2/agent/libexec/kubernetes /usr/src/image/libexec/kubernetes

# cleanup files hostname/hosts
RUN rm -rf \
    /usr/src/image/etc/hosts \
    /usr/src/image/etc/hostname \
    /usr/src/image/etc/alpine-release \
    /usr/src/image/etc/apk \
    /usr/src/image/etc/ca-certificates* \
    /usr/src/image/etc/os-release \
 && ln -s /usr/lib/os-release /usr/src/image/etc/os-release

# service cleanup
RUN rm -rf \
    /usr/src/image/etc/runlevels/boot/* \
    /usr/src/image/etc/runlevels/sysinit/* \
    /usr/src/image/etc/runlevels/default/* \
    /usr/src/image/etc/runlevels/shutdown/*

RUN rm -rf \
    /usr/src/image/bin/apt* \
    /usr/src/image/bin/debconf-apt* \
    /usr/src/image/etc/apt \
    /usr/src/image/etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
    /usr/src/image/etc/kernel/postinst.d/apt-auto-removal \
    /usr/src/image/etc/cron.daily/apt-compat \
    /usr/src/image/etc/logrotate.d/apt \
    /usr/src/image/lib/x86_64-linux-gnu/libapt-* \
    /usr/src/image/lib/dpkg/methods/apt \
    /usr/src/image/lib/apt \
    /usr/src/image/share/doc/apt \
    /usr/src/image/share/doc/libapt* \
    /usr/src/image/share/bash-completion/completions/apt* \
    /usr/src/image/share/bash-completion/completions/slapt* \
    /usr/src/image/share/bug/apt \
    /usr/src/image/lib/systemd \
    /usr/src/image/etc/systemd \
    /usr/src/image/bin/systemd-* \
    /usr/src/image/bin/deb-systemd-* \
    /usr/src/image/share/doc/libsystemd0 \
    /usr/src/image/games \
    /usr/src/image/lib/udev \
    /usr/src/image/share/applications \
    /usr/src/image/share/ca-certificates
COPY --from=progs /output/metadata /usr/src/image/sbin/metadata
COPY --from=progs /output/kubectx/kubectx /output/kubectx/kubens /usr/src/image/bin/

COPY overlay/ /usr/src/image/

RUN mv /usr/src/image/libexec/k3os /usr/src/image/libexec/rke2os                                  \
 && mv /usr/src/image/share/rancher/k3s /usr/src/image/share/rancher/rke2                         \
 && mv /usr/src/image/share/rancher/k3os /usr/src/image/share/rancher/rke2os                      \
 && mv /usr/src/image/etc/sysctl.d/00-k3os.conf /usr/src/image/etc/sysctl.d/00-rke2os.conf        \
 && rm -rf /usr/src/image/share/rancher/rke2/server/manifests/system-upgrade-plans                \
 && rm -f /usr/src/image/share/rancher/rke2/server/manifests/system-upgrade-controller.yaml       \
 && mv /usr/src/image/share/rancher/rke2os/scripts/k3os-upgrade-rootfs                            \
    /usr/src/image/share/rancher/rke2os/scripts/rke2os-upgrade-rootfs                             \
 && mv /usr/src/image/share/rancher/rke2os/scripts/k3os-upgrade-kernel                            \
    /usr/src/image/share/rancher/rke2os/scripts/rke2os-upgrade-kernel

COPY install.sh /usr/src/image/libexec/rke2os/install
COPY --from=rke2 /output/install.sh /usr/src/image/libexec/rke2os/rke2-install.sh

RUN mkdir -p /usr/src/image/etc/rancher/rke2                              \
 && ln -s /rke2os/system/rke2os/current/rke2os /usr/src/image/sbin/rke2os \
 && ln -s /rke2os/system/rke2/current/rke2 /usr/src/image/sbin/rke2       \
 && ln -s /var/lib/rancher/rke2/bin/kubectl /usr/src/image/sbin/kubectl   \
 && ln -s /var/lib/rancher/rke2/bin/crictl /usr/src/image/sbin/crictl     \
 && ln -s /var/lib/rancher/rke2/bin/ctr /usr/src/image/sbin/ctr           \
 && chown -R 1000:1000 /usr/src/image/etc/rancher

RUN sed -i -e "s/%VERSION%/${VERSION}/g" -e "s/%ARCH%/${ARCH}/g" /usr/src/image/lib/os-release  \
 && mkdir -p /output                                                                            \
 && mksquashfs /usr/src/image /output/rootfs.squashfs
