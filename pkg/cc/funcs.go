package cc

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"

	"github.com/rancher/k3os/pkg/command"
	"github.com/rancher/k3os/pkg/config"
	"github.com/rancher/k3os/pkg/hostname"
	"github.com/rancher/k3os/pkg/mode"
	"github.com/rancher/k3os/pkg/module"
	"github.com/rancher/k3os/pkg/ssh"
	"github.com/rancher/k3os/pkg/sysctl"
	"github.com/rancher/k3os/pkg/version"
	"github.com/rancher/k3os/pkg/writefile"
	"github.com/sirupsen/logrus"
)

func ApplyModules(cfg *config.CloudConfig) error {
	return module.LoadModules(cfg)
}

func ApplySysctls(cfg *config.CloudConfig) error {
	return sysctl.ConfigureSysctl(cfg)
}

func ApplyHostname(cfg *config.CloudConfig) error {
	return hostname.SetHostname(cfg)
}

func ApplyPassword(cfg *config.CloudConfig) error {
	return command.SetPassword(cfg.RKE2OS.Password)
}

func ApplyRuncmd(cfg *config.CloudConfig) error {
	return command.ExecuteCommand(cfg.Runcmd)
}

func ApplyBootcmd(cfg *config.CloudConfig) error {
	return command.ExecuteCommand(cfg.Bootcmd)
}

func ApplyInitcmd(cfg *config.CloudConfig) error {
	return command.ExecuteCommand(cfg.Initcmd)
}

func ApplyWriteFiles(cfg *config.CloudConfig) error {
	writefile.WriteFiles(cfg)
	return nil
}

func ApplySSHKeys(cfg *config.CloudConfig) error {
	return ssh.SetAuthorizedKeys(cfg, false)
}

func ApplySSHKeysWithNet(cfg *config.CloudConfig) error {
	return ssh.SetAuthorizedKeys(cfg, true)
}

func ApplyK3SWithRestart(cfg *config.CloudConfig) error {
	return ApplyK3S(cfg, true, false)
}

func ApplyK3SInstall(cfg *config.CloudConfig) error {
	return ApplyK3S(cfg, true, true)
}

func ApplyK3SNoRestart(cfg *config.CloudConfig) error {
	return ApplyK3S(cfg, false, false)
}

func ApplyK3S(cfg *config.CloudConfig, restart, install bool) error {
	mode, err := mode.Get()
	if err != nil {
		return err
	}
	if mode == "install" {
		return nil
	}

	k3sExists := false
	k3sLocalExists := false
	if _, err := os.Stat("/sbin/rke2"); err == nil {
		k3sExists = true
	}
	if _, err := os.Stat("/usr/local/bin/rke2"); err == nil {
		k3sLocalExists = true
	}

	args := cfg.RKE2OS.Rke2Args
	vars := []string{
		"INSTALL_RKE2_NAME=service",
	}

	if !k3sExists && !restart {
		return nil
	}

	if k3sExists {
                vars = append(vars, "INSTALL_RKE2_SKIP_DOWNLOAD=true")
		vars = append(vars, "INSTALL_RKE2_TAR_PREFIX=/sbin")
	} else if k3sLocalExists {
		vars = append(vars, "INSTALL_RKE2_SKIP_DOWNLOAD=true")
                vars = append(vars, "INSTALL_RKE2_TAR_PREFIX=/usr/local/bin")
	} else if !install {
		return nil
	}

	if !restart {
		vars = append(vars, "INSTALL_RKE2_SKIP_START=true")
	}

	if cfg.RKE2OS.ServerURL == "" {
		if len(args) == 0 {
			args = append(args, "server")
		}
	} else {
		vars = append(vars, fmt.Sprintf("RKE2_URL=%s", cfg.RKE2OS.ServerURL))
		if len(args) == 0 {
			args = append(args, "agent")
		}
	}

	if strings.HasPrefix(cfg.RKE2OS.Token, "K10") {
		vars = append(vars, fmt.Sprintf("RKE2_TOKEN=%s", cfg.RKE2OS.Token))
	} else if cfg.RKE2OS.Token != "" {
		vars = append(vars, fmt.Sprintf("RKE2_CLUSTER_SECRET=%s", cfg.RKE2OS.Token))
	}

	var labels []string
	for k, v := range cfg.RKE2OS.Labels {
		labels = append(labels, fmt.Sprintf("%s=%s", k, v))
	}
	if mode != "" {
		labels = append(labels, fmt.Sprintf("rke2os.io/mode=%s", mode))
	}
	labels = append(labels, fmt.Sprintf("rke2os.io/version=%s", version.Version))
	sort.Strings(labels)

	for _, l := range labels {
		args = append(args, "--node-label", l)
	}

	for _, taint := range cfg.RKE2OS.Taints {
		args = append(args, "--kubelet-arg", "register-with-taints="+taint)
	}

	cmd := exec.Command("/usr/libexec/rke2os/rke2-install.sh", args...)
	cmd.Env = append(os.Environ(), vars...)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	logrus.Debugf("Running %s %v %v", cmd.Path, cmd.Args, vars)

	return cmd.Run()
}

func ApplyInstall(cfg *config.CloudConfig) error {
	mode, err := mode.Get()
	if err != nil {
		return err
	}
	if mode != "install" {
		return nil
	}

	cmd := exec.Command("rke2os", "install")
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func ApplyDNS(cfg *config.CloudConfig) error {
	buf := &bytes.Buffer{}
	buf.WriteString("[General]\n")
	buf.WriteString("NetworkInterfaceBlacklist=veth\n")
	buf.WriteString("PreferredTechnologies=ethernet,wifi\n")
	if len(cfg.RKE2OS.DNSNameservers) > 0 {
		dns := strings.Join(cfg.RKE2OS.DNSNameservers, ",")
		buf.WriteString("FallbackNameservers=")
		buf.WriteString(dns)
		buf.WriteString("\n")
	} else {
		buf.WriteString("FallbackNameservers=8.8.8.8\n")
	}

	if len(cfg.RKE2OS.NTPServers) > 0 {
		ntp := strings.Join(cfg.RKE2OS.NTPServers, ",")
		buf.WriteString("FallbackTimeservers=")
		buf.WriteString(ntp)
		buf.WriteString("\n")
	}

	err := ioutil.WriteFile("/etc/connman/main.conf", buf.Bytes(), 0644)
	if err != nil {
		return fmt.Errorf("failed to write /etc/connman/main.conf: %v", err)
	}

	return nil
}

func ApplyWifi(cfg *config.CloudConfig) error {
	if len(cfg.RKE2OS.Wifi) == 0 {
		return nil
	}

	buf := &bytes.Buffer{}

	buf.WriteString("[WiFi]\n")
	buf.WriteString("Enable=true\n")
	buf.WriteString("Tethering=false\n")

	if buf.Len() > 0 {
		if err := os.MkdirAll("/var/lib/connman", 0755); err != nil {
			return fmt.Errorf("failed to mkdir /var/lib/connman: %v", err)
		}
		if err := ioutil.WriteFile("/var/lib/connman/settings", buf.Bytes(), 0644); err != nil {
			return fmt.Errorf("failed to write to /var/lib/connman/settings: %v", err)
		}
	}

	buf = &bytes.Buffer{}

	buf.WriteString("[global]\n")
	buf.WriteString("Name=cloud-config\n")
	buf.WriteString("Description=Services defined in the cloud-config\n")

	for i, w := range cfg.RKE2OS.Wifi {
		name := fmt.Sprintf("wifi%d", i)
		buf.WriteString("[service_")
		buf.WriteString(name)
		buf.WriteString("]\n")
		buf.WriteString("Type=wifi\n")
		buf.WriteString("Passphrase=")
		buf.WriteString(w.Passphrase)
		buf.WriteString("\n")
		buf.WriteString("Name=")
		buf.WriteString(w.Name)
		buf.WriteString("\n")
	}

	if buf.Len() > 0 {
		return ioutil.WriteFile("/var/lib/connman/cloud-config.config", buf.Bytes(), 0644)
	}

	return nil
}

func ApplyDataSource(cfg *config.CloudConfig) error {
	if len(cfg.RKE2OS.DataSources) == 0 {
		return nil
	}

	args := strings.Join(cfg.RKE2OS.DataSources, " ")
	buf := &bytes.Buffer{}

	buf.WriteString("command_args=\"")
	buf.WriteString(args)
	buf.WriteString("\"\n")

	if err := ioutil.WriteFile("/etc/conf.d/cloud-config", buf.Bytes(), 0644); err != nil {
		return fmt.Errorf("failed to write to /etc/conf.d/cloud-config: %v", err)
	}

	return nil
}

func ApplyEnvironment(cfg *config.CloudConfig) error {
	if len(cfg.RKE2OS.Environment) == 0 {
		return nil
	}
	env := make(map[string]string, len(cfg.RKE2OS.Environment))
	if buf, err := ioutil.ReadFile("/etc/environment"); err == nil {
		scanner := bufio.NewScanner(bytes.NewReader(buf))
		for scanner.Scan() {
			line := scanner.Text()
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "#") {
				continue
			}
			line = strings.TrimPrefix(line, "export")
			line = strings.TrimSpace(line)
			if len(line) > 1 {
				parts := strings.SplitN(line, "=", 2)
				key := parts[0]
				val := ""
				if len(parts) > 1 {
					if val, err = strconv.Unquote(parts[1]); err != nil {
						val = parts[1]
					}
				}
				env[key] = val
			}
		}
	}
	for key, val := range cfg.RKE2OS.Environment {
		env[key] = val
	}
	buf := &bytes.Buffer{}
	for key, val := range env {
		buf.WriteString(key)
		buf.WriteString("=")
		buf.WriteString(strconv.Quote(val))
		buf.WriteString("\n")
	}
	if err := ioutil.WriteFile("/etc/environment", buf.Bytes(), 0644); err != nil {
		return fmt.Errorf("failed to write to /etc/environment: %v", err)
	}

	return nil
}
