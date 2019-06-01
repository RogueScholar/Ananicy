# Ananicy - ANother Auto NICe-Y daemon

## Description
Ananicy is a simple daemon written in Bash to manage processes' [I/O](http://linux.die.net/man/1/ionice) and [CPU](http://linux.die.net/man/1/nice) priorities, with a crowdsourced ruleset for popular applications. (New rules are always welcome; use GitHub's [Pull request](https://help.github.com/articles/using-pull-requests/) mechanism.)

The current development philosophy is concerned only with usage on desktop (as opposed to server) systems.

I just wanted a tool for auto set programs nice in my system, i.e.:
* Why do I have a lags, while compiling kernel and playing a game?
* Why does dropbox client eat all my IO?
* Why does torrent/dc client make my laptop run slower?
* ...

Use ananicy to fix your problems!

## Versions

```
X.Y.Z where
X - Major version,
Y - Script version - reset on each major update
Z - Rules version - reset on each script update
```
Read more about semantic versioning [here](http://semver.org/)

## Dependencies

To use ananicy you must have systemd installed.

* On Debian-based distributions

  ```bash
  sudo apt -y install systemd
  ```

## Installation

* You can install ananicy manually with the following commands:

  ```bash
  git clone https://github.com/Nefelim4ag/Ananicy.git /tmp/ananicy
  cd /tmp/ananicy
  sudo make install
  ```

* ![logo](http://www.monitorix.org/imgs/archlinux.png "arch logo") Arch: [AUR/ananicy-git](https://aur.archlinux.org/packages/ananicy-git)

  ```bash
  yay -S ananicy-git
  ```

* Debian/Ubuntu: Use included script [package.sh](package.sh) in repository root directory

  ```bash
  git clone https://github.com/Nefelim4ag/Ananicy.git
  cd Ananicy
  ./package.sh deb
  sudo dpkg -i ./tmp/ananicy-*.deb
  ```

* systemd: Enable the background service (Optional)

  ```bash
  sudo systemctl enable ananicy
  sudo systemctl start ananicy
  ```
  
## Configuration

Rules files should be placed under /etc/ananicy.d/ directory and have *.rules extension.
Inside the .rules file every process is described in a separate JSON array; general
syntax is described below:

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

All fields except 'name' are optional.

'name' used for match processes can be found using the PID of any running process
_(Replace <process> with the name of the executable you wish to create rules for)_

```bash
basename $(sudo realpath /proc/$(pidof <process>)/exe)
```

Currently match by other things, not supported.

You can check what Ananicy see, by:

```bash
ananicy dump proc
```

Ananicy load all rules in ram while starting, so to apply rules, you must restart service.

Available ionice values:

```bash
man ionice
```

## Simple rules for writing rules

CFQ IO Scheduller also use 'nice' for internal scheduling, so it's mean processes with same IO class and IO priority, but with different nicceness will take advantages of 'nice' also for IO.

1. Try don't chage 'nice' of system wide process like initrd.
1. Please try use full process name (or name with ^$ symbols like NAME=^full_name$)
1. When writing rule - try use only 'nice', it must be enough in most cases.
1. Don't try set to high priority! Niceness can fix some performance problems, but can't give you more.
Example: pulseaudio uses 'nice' -11 by default, if you set other cpu hungry task, with 'nice' {-20..-12} you can catch a sound glitches.
1. For CPU hungry backround task like compiling, just use NICE=19.

About IO priority:

1. It's usefull use '{"ioclass": "idle"}' for IO hungry background tasks like: file indexers, Cloud Clients, Backups and etc.
1. It's not cool set realtime to all tasks. The  RT  scheduling  class is given first access to the disk, regardless of what else is going on in the system.  Thus the RT class needs to be used with some care, as it can starve other processes. So try use ioclass first.

## Debugging

Get ananicy output with journalctl:

```bash
journalctl -efu ananicy.service
```

### Missing `schedtool`

If you see this error in the output

  `... ananicy[.....]: ERRO: Missing schedtool! Abort!`

The solution (on Debian-based distributions) is:

  ```bash
  sudo apt -y install schedtool
  ```

### Submitting new rules

Please use [pull requests](https://github.com/Nefelim4ag/Ananicy/compare). Thank you.
