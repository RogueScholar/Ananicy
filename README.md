# Ananicy - ANother Auto NICe-Y daemon

## Description

Ananicy is a simple daemon written in Python to manage processes'
[I/O](http://linux.die.net/man/1/ionice) and
[CPU](http://linux.die.net/man/1/nice) priorities, with a crowdsourced ruleset
for popular applications. (New rules are always welcome; use GitHub's
[Pull request](https://help.github.com/articles/using-pull-requests/)
mechanism.)

The current development philosophy is concerned only with usage on desktops (as
opposed to server) systems.

I just wanted a tool for auto set programs nice in my system, i.e.:

- Why do I have a lags, while compiling kernel and playing a game?
- Why does dropbox client eat all my IO?
- Why does torrent/dc client make my laptop run slower?
- ...

Use ananicy to fix your problems!

## Versions

```shell
X.Y.Z where
X - Major version,
Y - Script version - reset on each major update
Z - Rules version - reset on each script update
```

Read more about semantic versioning [here](https://semver.org/)

## Dependencies

To use ananicy you must have systemd installed.

### On Debian-based distributions

```shell
sudo apt -y install systemd
```

## Installation

You can install Ananicy manually with the following commands:

```shell
git clone https://github.com/Nefelim4ag/Ananicy.git && cd Ananicy
sudo make install
```

### [![Arch logo][Arch]] On Arch-based distributions: [AUR/ananicy-git][AUR]

```shell
yay -S ananicy-git
```

### On Debian-based distributions

Use the included script [package.sh](package.sh) in the repository root

```shell
git clone https://github.com/Nefelim4ag/Ananicy.git && cd Ananicy
./package.sh deb
sudo dpkg -i ./tmp/ananicy-*.deb
```

### Post-installation steps (optional)

- systemd: Enable the background service (autostarts Ananicy during system boot)

```shell
sudo systemctl enable ananicy
sudo systemctl start ananicy
```

## Configuration

### Defining rules

Rules files should be placed in the `/etc/ananicy.d` directory and have a
`.rules` file extension. Inside the .rules file, every process is described in a
separate JSON array; the general syntax is described below:

```json
{
  "name": "gcc",
  "type": "Heavy_CPU",
  "nice": 19,
  "ioclass": "best-effort",
  "ionice": 7,
  "cgroup": "cpu90"
}
```

All fields except 'name' are optional. 'name' is used to match processes with
their "arg0", which can be found for any active process on your system if you
know its current PID (process ID number).

> Replace \<process\> with the name of the executable you wish to create rules
> for

```shell
basename "$(realpath -Leq "/proc/$(pidof <process>)/exe")"
```

Currently, matching processes by any other methods are not supported.

You can check what Ananicy sees by invoking the following command:

```shell
ananicy dump proc
```

### Loading new/modified rules

Ananicy loads all rules found in `/etc/ananicy.d` into active memory when it
starts, so to apply new or modified rules, you must restart the service using
systemd.

### Nice values

ionice is a well-documented Unix-like feature, and you should familiarize
yourself with its theory of operation and the range of valid ionice values
using:

```shell
man ionice
```

## Simple rules for writing rules

The CFQ IO scheduler also uses 'nice' for internal scheduling, so that processes
from the same I/O class and with the same I/O priority, but with differing
niceness will behave in likewise fashion regarding IO as well.

1. Try don't change the 'niceness' of system-wide process like initrd.
1. Try to use the full process name, or use a regular expression for the name
   with the `^`/`$` symbols, as in `NAME=^full_name$`.
1. When writing rules, always start by altering just the 'niceness', it will be
   enough in most cases.
1. Don't try set to high priority! Niceness can fix some performance problems,
   but it can't give you more hardware resources out of thin air.
   > Example: pulseaudio has a 'nice' value of -11 by default. If you assign
   > another CPU-hungry task running on your system to have a lower 'nice' value
   > (i.e. between -12 and -20, inclusive) any audio you try to play with likely
   > start to skip or cut out.
1. For CPU-hungry background tasks like compiling software from source code,
   just use a 'nice' value of 19.

### About I/O priority

1. It's usefull use `{"ioclass": "idle"}` for I/O-hungry background tasks like:
   file indexers, cloud storage synchronization clients, backup managers and the
   like.
1. It's not cool to set all tasks to run in realtime mode. The realtime
   scheduling class is given priority access to your mounted volumes, regardless
   of anything else the system is trying to do. Thus, the realtime class needs
   to be used judiciously and only when absolutely needed, as it can starve all
   the other processes of file access. If this is confusing, just obey Rule #1.

## Debugging

View Ananicy's output messages using journalctl:

```shell
journalctl -efu ananicy.service
```

### schedtool

Installing Ananicy as a Debian or AUR package will automatically install the
necessary dependencies at the same time. If you built and installed from source,
though, it's possible you may see the error shown below in your output:

`... ananicy[.....]: ERRO: Missing schedtool! Abort!`

The solution is to install the `schedtool` package and restart Ananicy. On
Debian-based distributions this can be done using the command:

```shell
sudo apt -y install schedtool
```

### Submitting new rules

Please use [pull requests][PR]. Thank you.

[AUR]: https://aur.archlinux.org/packages/ananicy-git
[Arch]: http://www.monitorix.org/imgs/archlinux.png
[PR]: https://github.com/Nefelim4ag/Ananicy/compare
