---
name: windows-sysadmin
description: Diagnose and operate Windows systems, including services, the registry, Event Log, scheduled tasks, Defender Firewall, networking, storage, users and permissions, updates, and winget packages. Use when asked to troubleshoot Windows hosts, prepare commands, write runbooks, fix service failures, or reason about Windows administration.
---

# windows-sysadmin

## Scope

One host's operating system. Reach for `linux-sysadmin` on Linux hosts, and for
`infrastructure` when the change or outage crosses machines.

## Workflow

1. Gather host, service, resource, network, and security diagnostics.
2. Determine impact and recent changes.
3. Create rollback for registry keys, services, scheduled tasks, and firewall
   rules.
4. Implement the smallest fix.
5. Validate runtime behavior and persistence across reboot.

## Diagnostics

```powershell
Get-ComputerInfo -Property OsName, OsVersion, OsBuildNumber, CsName
Get-Uptime
Get-Volume
Get-Service <name>
Get-CimInstance Win32_Service -Filter "Name='<name>'" | Select-Object StartMode, State, StartName, PathName
Get-WinEvent -LogName System -MaxEvents 50
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Level = 1, 2; StartTime = (Get-Date).AddHours(-6) }
Get-NetTCPConnection -State Listen | Sort-Object LocalPort
Get-NetFirewallProfile | Select-Object Name, Enabled
Get-ScheduledTask | Where-Object State -ne 'Disabled'
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
winget list --upgrade-available
```

Run an elevated session for service, registry, firewall, and Event Log security
queries. Note in the runbook which steps require elevation.

## Registry rules

- Use PSDrive prefixes: `HKLM:\SOFTWARE\...` and `HKCU:\...`, never raw
  `HKEY_LOCAL_MACHINE\...`.
- Export a key with `reg export` before changing it, and record the restore
  command alongside the change.
- Prefer policy-supported settings over undocumented keys.
- Never use `New-Item -Force` on an existing value you intend to keep; it
  truncates.

## Safety rules

- Never disable Defender or the firewall as a default fix.
- Never change RDP, WinRM, or firewall rules on a remote host without an
  out-of-band recovery path; a bad rule can end the session permanently.
- Confirm which firewall profile is active before editing rules, because a rule
  in the wrong profile silently does nothing.
- Prefer a service recovery configuration over a scheduled restart loop.
- Preserve ACLs, ownership, and inheritance. Record `icacls <path> /save` output
  before changing permissions.
- Check whether a setting is enforced by Group Policy before editing it locally,
  because policy will revert the change.
- Treat `winget upgrade --all` as a change with rollback implications, not a
  routine command.

## Validation

- Service starts now and after reboot, with the intended start mode and account.
- Event Log shows no new errors after the change.
- Expected ports listen and unexpected ports do not.
- Remote access still works, verified from a second session before closing the
  first.
- Firewall and Defender state match the intended policy.
- Registry changes survive reboot and are not reverted by Group Policy.
