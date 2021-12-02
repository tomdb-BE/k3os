
# --- add quotes to command arguments ---
quote() {
    for arg in "$@"; do
        printf '%s\n' "$arg" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
    done
}

# --- add indentation and trailing slash to quoted args ---
quote_indent() {
    printf ' \\\n'
    for arg in "$@"; do
        printf '\t%s \\\n' "$(quote "$arg")"
    done
}

# --- escape most punctuation characters, except quotes, forward slash, and space ---
escape() {
    printf '%s' "$@" | sed -e 's/\([][!#$%&()*;<=>?\_`{|}]\)/\\\1/g;'
}

# --- escape double quotes ---
escape_dq() {
    printf '%s' "$@" | sed -e 's/"/\\"/g'
}

# --- set envs for openrc service install ---
setup_openrc_envs() {
    BIN_DIR=/sbin
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then
        SUDO=
    fi
    case "$1" in
        # --- if we only have flags discover if command should be server or agent ---
        (-*|"")
            if [ -z "${RKE2_URL}" ]; then
                CMD_RKE2=server
            else
                if [ -z "${RKE2_TOKEN}" ] && [ -z "${RKE2_TOKEN_FILE}" ]; then
                    fatal "Defaulted rke2 exec command to 'agent' because RKE2_URL is defined, but RKE2_TOKEN or RKE2_TOKEN_FILE is not defined."
                fi
                CMD_RKE2=agent
            fi
        ;;
        # --- command is provided ---
        (*)
            CMD_RKE2=$1
            shift
        ;;
    esac
    CMD_RKE2_EXEC="${CMD_RKE2}$(quote_indent "$@")"

    # --- use service name if defined or create default ---
    if [ -n "${INSTALL_RKE2_NAME}" ]; then
        SYSTEM_NAME=rke2-${INSTALL_RKE2_NAME}
    else
        SYSTEM_NAME=rke2-service
    fi

    SERVICE_RKE2=${SYSTEM_NAME}.service
    KILLALL_RKE2_SH=${KILLALL_RKE2_SH:-${BIN_DIR}/rke2-killall.sh}
    FILE_RKE2_SERVICE=/etc/init.d/${SYSTEM_NAME}
    FILE_RKE2_ENV=/etc/rancher/rke2/${SYSTEM_NAME}.env
}

get_installed_hashes() {
    $SUDO sha256sum ${BIN_DIR}/rke2 ${FILE_RKE2_SERVICE} ${FILE_RKE2_ENV} 2>&1 || true
}

# --- capture current env and create file containing rke2_ variables ---
create_env_file() {
    info "env: Creating environment file ${FILE_RKE2_ENV}"
    $SUDO mkdir -p /etc/rancher/rke2
    $SUDO touch ${FILE_RKE2_ENV}
    $SUDO chmod 0600 ${FILE_RKE2_ENV}
    sh -c export | while read x v; do echo $v; done | grep -E '^(RKE2|CONTAINERD)_' | $SUDO tee ${FILE_RKE2_ENV} >/dev/null
    sh -c export | while read x v; do echo $v; done | grep -Ei '^(NO|HTTP|HTTPS)_PROXY' | $SUDO tee -a ${FILE_RKE2_ENV} >/dev/null
}

# --- write openrc service file ---
create_openrc_service_file() {
    LOG_FILE=/var/log/${SYSTEM_NAME}.log

    info "openrc: Creating service file ${FILE_RKE2_SERVICE}"
    $SUDO tee ${FILE_RKE2_SERVICE} >/dev/null << EOF
#!/sbin/openrc-run
depend() {
    after network-online
    want cgroups
}
start_pre() {
    rm -f /tmp/k3s.*
    rm -f /tmp/rke2.*
}
supervisor=supervise-daemon
name=${SYSTEM_NAME}
command="${BIN_DIR}/rke2"
command_args="$(escape_dq "${CMD_RKE2_EXEC}")
    >>${LOG_FILE} 2>&1"
output_log=${LOG_FILE}
error_log=${LOG_FILE}
pidfile="/var/run/${SYSTEM_NAME}.pid"
respawn_delay=5
respawn_max=0
set -o allexport
if [ -f /etc/environment ]; then source /etc/environment; fi
if [ -f ${FILE_RKE2_ENV} ]; then source ${FILE_RKE2_ENV}; fi
set +o allexport
EOF
    $SUDO chmod 0755 ${FILE_RKE2_SERVICE}

    $SUDO tee /etc/logrotate.d/${SYSTEM_NAME} >/dev/null << EOF
${LOG_FILE} {
	missingok
	notifempty
	copytruncate
}
EOF
}

# --- enable and start openrc service ---
openrc_enable() {
    info "openrc: Enabling ${SYSTEM_NAME} service for default runlevel"
    $SUDO rc-update add ${SYSTEM_NAME} default >/dev/null
}

openrc_start() {
    info "openrc: Starting ${SYSTEM_NAME}"
    $SUDO ${FILE_RKE2_SERVICE} restart
}

# --- startup systemd or openrc service ---
service_enable_and_start() {
    if [ -f "/proc/cgroups" ] && [ "$(grep memory /proc/cgroups | while read -r n n n enabled; do echo $enabled; done)" -eq 0 ];
    then
        info 'Failed to find memory cgroup, you may need to add "cgroup_memory=1 cgroup_enable=memory" to your linux cmdline (/boot/cmdline.txt on a Raspberry Pi)'
    fi
    [ "${INSTALL_RKE2_SKIP_ENABLE}" = true ] && return
    openrc_enable
    [ "${INSTALL_RKE2_SKIP_START}" = true ] && return

    POST_INSTALL_HASHES=$(get_installed_hashes)
    if [ "${PRE_INSTALL_HASHES}" = "${POST_INSTALL_HASHES}" ] && [ "${INSTALL_K3S_FORCE_RESTART}" != true ]; then
        info 'No change detected so skipping service start'
        return
    fi
    openrc_start
    return 0
}

# --- cleanup installed files for rke2os install  ---
do_rke2os_cleanup () {
    mv ${INSTALL_RKE2_TAR_PREFIX}/bin/* ${INSTALL_RKE2_TAR_PREFIX}/
    rm -r ${INSTALL_RKE2_TAR_PREFIX}/bin ${INSTALL_RKE2_TAR_PREFIX}/lib ${INSTALL_RKE2_TAR_PREFIX}/share ${INSTALL_RKE2_TAR_PREFIX}/*.ps1
}

# --- re-evaluate args to include env command ---
eval set -- $(escape "${INSTALL_RKE2_EXEC}") $(quote "$@")

# --- run the service install process --
{
setup_openrc_envs "$@"
PRE_INSTALL_HASHES=$(get_installed_hashes)
if [ "${INSTALL_RKE2_SKIP_DOWNLOAD}" != true ]; then
    do_install
    do_rke2os_cleanup
fi
create_env_file
create_openrc_service_file
service_enable_and_start
exit 0
}
