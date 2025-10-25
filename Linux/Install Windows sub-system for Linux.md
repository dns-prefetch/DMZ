---
<img src="https://raw.githubusercontent.com/dns-prefetch/DMZ/refs/heads/main/Assets/images/global/dmz-header.svg" width="100%" height="10%">

##### Published 18/08/2025 10:44:05; Revised: None

# How to install WSL and Oracle Linux onto your windows device

[Microsoft WSL documentation](https://learn.microsoft.com/en-us/windows/wsl/)

## But first some background

Almost (almost) everything you need to start using Oracle Linux on your windows machine is documented on the excellent Microsoft documentation site.  However there are a number of details that need to be researched and implemented to get a working installation up and running.

As a little background history to this article, I used to run Oracle Linux on my windows machines inside VirtualBox and this was a pattern I followed for approximately 15 years.  During this time, I started building virtual machines inside my Oracle cloud infrastructure tenancy, and this has been a great pattern for working with proof of concept jobs, but when I'm developing code on Linux, I prefer to minimize the network distance between my windows device and my virtual machine. Minimizing the network hops when I am busy and concentrating help to reduce to edit/save cycle delays smoooth my flow of consciousness.

So, now I have Oracle Cloud virtual machines, and WSL virtual machines.  I no longer have a need for VirtualBox.

This is my plan
- Install WSL
- Install Oracle Linux
- Configure the Linux installation to automatically start systemd
- Move the WSL hard disk image for Oracle Linux to my D: drive

Initially I was concerned about the practicality of the resources demands of Oracle Linux running inside WSL on Windows, but the hardware requirements are surprisingly low. To give you some idea of what my working environment includes; I have a tiny, quiet, low power machine that I use for the daily work:
- MeLE Quieter 4C fanless mini PC
- Intel N150, 16gb RAM, 500gb SSD
- Windows 11
- Windows drive C is 200gb
- Windows drive D is 266gb, this drive is encrypted with BitLocker

On to the MeLE I installed WSL along with Oracle Linux 9.5.  This is a fully working Oracle Linux running systemd which automatically starts the Linux background services.  WSL is default configured to start manually.

After a relatively small amount of research and investigation, these are my working notes.

## Install the WSL dependencies

Using a command or powershell prompt

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /Online /enable-feature /All /FeatureName:Microsoft-Hyper-V
```

## Install and update WSL

Using a command or powershell prompt

```
wsl --install
wsl --update
```

## Create the initial default WSL configuration settings

These are my preferred default settings across all my WSL Linux installations.  These settings can also be configured using the WSL settings application (windows search: wsl settings).

Create and edit the WSL configuration file

```
%UserProfile%\.wslconfig
```

Then add the following, and save.

```
[wsl2]
memory=5GB
processors=2
swap=8GB
defaultVhdSize=20000000000
vmIdleTimeout=50000
[experimental]
sparseVhd=true
```

## Install and configure Oracle Linux

Using a command or powershell prompt

```
wsl --install -d OracleLinux_9_5
```

The prompt should now be within Oracle Linux, ensure you are root then add this configuration

```
cat << END > /etc/wsl.conf
[boot]
systemd=true
[automount]
enabled=true
END
```

Exit the Linux vm.

(If you are new to WSL, you will be surprised to discover that starting the VM is as simple as running wsl.exe. This will start the VM and create a session within the VM.)

## Move the Linux virtual disk from C: to D:

There are two reason for the relocation of the virtual disk, the first the C: drive is where I keep windows and the binary installations.  D: is encrypted and used primarily for my working material.

This is the plan
- Create the target folder on D:
- Shutdown Oracle Linux
- Export and unregister the VM from C:
- Import and register the VM to D:

```
mkdir D:\WSL
mkdir D:\WSL\OEL95

wsl --shutdown
wsl -t OracleLinux_9_5

wsl --export OracleLinux_9_5 "D:\WSL\oel95-ex.tar"
wsl --unregister OracleLinux_9_5

wsl --import OracleLinux_9_5 "D:\WSL\OEL95" "D:\WSL\oel95-ex.tar"

wsl --set-default OracleLinux_9_5
```

# Miscellanious brain joggers for me

```
wsl --list --verbose
wsl --list --online
wsl --list --all
wsl --set-default <Distribution Name>
wsl --distribution <Distribution Name> --user <User Name>
wsl --status
wsl --version
wsl --shutdown

wsl hostname -l
ip route show | grep -i default | awk '{ print $3}'
netsh interface ipv4 show neighbors
```

---