## OPENRC UBUNTU Build ###
FROM ubuntu:focal AS openrc-builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /packages
RUN chown -R _apt:root /packages \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends \
    apt-src \
    ca-certificates \
    gnupg \
 && gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 \
 && gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 \
 && gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 605C66F00D6C9793 \
 && gpg --export 648ACFD622F3D138 | apt-key add - \
 && gpg --export 0E98404D386FA1D9 | apt-key add - \
 && gpg --export 605C66F00D6C9793 | apt-key add - \
 && echo "deb-src http://ftp.debian.org/debian bullseye main" >> /etc/apt/sources.list \
 && apt-get update -y \
 && apt-src update \
 && apt-src install insserv \
 && apt-src build insserv \
 && apt-src install openrc \
 && apt-src build openrc

### BASE ###
FROM ubuntu:focal AS base
ARG ARCH
ARG DEBIAN_FRONTEND=noninteractive
COPY --from=openrc-builder /packages/*.deb /tmp/
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends /tmp/insserv_1.21.0-1.1_amd64.deb /tmp/libeinfo1_0.42-2.1_amd64.deb /tmp/librc1_0.42-2.1_amd64.deb /tmp/openrc_0.42-2.1_amd64.deb \
 && apt-get install -y --no-install-recommends \
    bash \
    bash-completion \
    busybox \
    ca-certificates \
    connman \
    conntrack \
    coreutils \
    cryptsetup \
    curl \
    dbus \
    dmidecode \
    dosfstools \
    e2fsprogs \
    efibootmgr \
    findutils \
    glusterfs-client \
    grub2 \
    haveged \
    htop \
    iproute2 \
    iptables \
    irqbalance \
    jq \
    kbd \
    libusb-0.1-4 \
    logrotate \
    lsscsi \
    lvm2 \
    mdadm \
    mdevctl \
    multipath-tools \
    nfs-client \
    open-iscsi \
    openssh-client \
    openssh-server \
    parted \
    procps \
    qemu-guest-agent \
    rng-tools \
    rsync \
    strace \
    smartmontools \
    sudo \
    tar \
    tzdata \
    util-linux \
    vim \
    wireguard-tools \
    wpasupplicant \
    xfsprogs \
    xz-utils \
 && rm -r /tmp/* \
# replicate the default "no idea, friend" behavior of virt-what
 && touch /usr/sbin/virt-what \
 && chmod +x /usr/sbin/virt-what
