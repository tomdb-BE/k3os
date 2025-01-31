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
 && apt-src install initscripts \
 && apt-src build initscripts \
 && apt-src install openrc \
 && apt-src build openrc

### BASE ###
FROM ubuntu:focal AS base
ARG ARCH
ARG DEBIAN_FRONTEND=noninteractive
COPY --from=openrc-builder /packages/*.deb /tmp/
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends /tmp/insserv_1.21.0-1.1_${ARCH}.deb /tmp/libeinfo1_0.42-2.1_${ARCH}.deb /tmp/librc1_0.42-2.1_${ARCH}.deb /tmp/initscripts_2.96-7_all.deb /tmp/openrc_0.42-2.1_${ARCH}.deb \
 && apt-get install -y --no-install-recommends --reinstall openrc \
 && apt-get install -y --no-install-recommends \
    bash-completion \
    busybox-static \
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
    grub-efi-${ARCH} \
    haveged \
    htop \
    iproute2 \
    iptables \
    irqbalance \
    jq \
    kbd \
    libusb-0.1-4 \
    logrotate \
    lvm2 \
    mdadm \
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
    udev \
    util-linux \
    wireguard-tools \
    wpasupplicant \
    xfsprogs \
 && rm -r /tmp/* \
# replicate the default "no idea, friend" behavior of virt-what
 && touch /usr/sbin/virt-what \
 && chmod +x /usr/sbin/virt-what
# Set Busybox links
RUN busybox --install -s

