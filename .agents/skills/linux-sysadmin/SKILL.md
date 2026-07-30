---
name: linux-sysadmin
description: Diagnose and operate the operating system of a single Linux host, especially Ubuntu, including SSH, SELinux, permissions, firewalls, packages, processes, logs, and systemd services. Use when troubleshooting one machine, fixing a service failure, preparing host commands, or writing a host runbook. For work spanning several machines, storage appliances, DNS, or reverse proxies, use infrastructure instead.
---

# linux-sysadmin

## Scope

One host's operating system. Reach for `infrastructure` when the change or
outage crosses machines, and for `windows-sysadmin` on Windows hosts.

## Workflow

1. Gather host, service, resource, network, and security diagnostics.
2. Determine impact and recent changes.
3. Create rollback for files, packages, service units, and firewall changes.
4. Implement the smallest fix.
5. Validate runtime behavior and boot persistence.

## Diagnostics

```bash
cat /etc/os-release
uname -a
uptime
free -h
df -h
lsblk
systemctl status <unit>
journalctl -xeu <unit>
ss -tulpn
getenforce
firewall-cmd --list-all
ufw status verbose
```

## Safety Rules

- Never disable SELinux as a default fix.
- Never rotate SSH keys or change `sshd_config` without rollback.
- Never modify firewall rules without confirming active firewall stack.
- Prefer systemd drop-ins over editing packaged unit files.
- Preserve ownership, permissions, ACLs, mount options, and labels.

## Validation

- Service starts now and after reboot.
- Logs show no new errors.
- Expected ports listen and unexpected ports do not.
- SSH access still works.
- SELinux and firewall state match the intended policy.
