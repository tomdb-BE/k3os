# --- set envs for openrc service install ---
setup_openrc_envs() {
    SYSTEM_NAME=rke2-service
    FILE_RKE2_SERVICE=/etc/init.d/${SYSTEM_NAME}
    FILE_RKE2_ENV=/etc/rancher/rke2/${SYSTEM_NAME}.env
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
        if [ "${CMD_RKE2}" = server ]; then
            SYSTEM_NAME=rke2
        else
            SYSTEM_NAME=rke2-${CMD_RKE2}
        fi
    fi
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

# --- cleanup installed files for rke2os install  ---
do_rke2os_cleanup () {
    mv ${INSTALL_RKE2_TAR_PREFIX}/bin/* ${INSTALL_RKE2_TAR_PREFIX}/
    rm -r ${INSTALL_RKE2_TAR_PREFIX}/bin ${INSTALL_RKE2_TAR_PREFIX}/lib ${INSTALL_RKE2_TAR_PREFIX}/share
}

# --- re-evaluate args to include env command ---
eval set -- $(escape "${INSTALL_RKE2_EXEC}") $(quote "$@")

# --- run the service install process --
{
setup_openrc_envs "$@"
create_openrc_service_file
[ "${INSTALL_RKE2_SKIP_DOWNLOAD}" = true ] && exit 0
do_install
do_rke2os_cleanup
exit 0
}
