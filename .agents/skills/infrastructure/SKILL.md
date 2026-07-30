---
name: infrastructure
description: Operate and troubleshoot self-hosted infrastructure spanning several machines, including hypervisors such as Proxmox, storage such as TrueNAS and NFS or SMB, DNS, reverse proxies, networking, and backups, across mixed Linux and Windows hosts. Use when planning maintenance, diagnosing an outage across services, or making a change whose blast radius reaches more than one machine or the network itself. For work confined to one host's operating system, use linux-sysadmin or windows-sysadmin instead.
---

# infrastructure

## Scope

Infrastructure across machines, whatever operating system each host runs. The
concerns here are blast radius, service dependencies, and recoverability rather
than any single host's configuration.

Reach for `linux-sysadmin` or `windows-sysadmin`, whichever matches the host,
once the work is confined to one machine's operating system.

## Workflow

1. Gather diagnostics from the affected hosts and the network path between them.
2. Determine user impact and blast radius, including which services depend on
   the one being changed.
3. Create rollback, and confirm an access path that survives the change failing.
4. Implement the smallest safe change.
5. Validate service, network, storage, and reboot persistence.

## Diagnostics

Linux hosts:

```bash
hostnamectl
ip addr
ip route
systemctl status <service>
journalctl -xeu <service>
ss -tulpn
df -h
lsblk
findmnt
```

Windows hosts:

```powershell
Get-NetIPConfiguration
Get-Service <name>
Get-NetTCPConnection -State Listen
Get-SmbShare
Get-SmbMapping
Get-Volume
```

Network and service reachability, from whichever host is convenient:

```bash
dig <name>
curl -vk <url>
```

```powershell
Resolve-DnsName <name>
Test-NetConnection <host> -Port <port>
Invoke-WebRequest -Uri <url> -SkipCertificateCheck
```

Check name resolution and reachability from a client that actually uses the
service, not only from the host running it. A service can be healthy locally and
unreachable from everywhere that matters.

## Safety rules

- Never destroy data without explicit approval.
- Never modify firewall or DNS blindly.
- Never change networking without rollback and out-of-band access. This applies
  equally to a Linux host over SSH and a Windows host over RDP or WinRM.
- Treat storage, reverse proxy, and network file share changes as high
  blast-radius work.
- Confirm what depends on a service before restarting it. A hypervisor, storage
  appliance, or DNS resolver usually has dependents that fail quietly.
- Prefer incremental config changes over broad rewrites.
- Verify a backup is restorable before a change that relies on it.

## Validation

- Service starts now and after reboot.
- Mounts and network shares reconnect after reboot on every client that uses
  them.
- DNS resolves from expected clients, not only from the server.
- Reverse proxy routes to the expected backend, including after the backend
  restarts.
- Dependent services recovered rather than merely the changed one.
- Logs show no new errors on the changed host or its dependents.
