# Ananicy - ANother Auto NICe-Y daemon

## Description

Ananicy (ANother Auto NICe daemon) — is a shell daemon created to manage
processes' [IO](http://linux.die.net/man/1/ionice) and
[CPU](http://linux.die.net/man/1/nice) priorities, with a community-driven set
of rules for popular applications (anyone may add their own rule via GitHub's
[pull request](https://help.github.com/articles/using-pull-requests/)
mechanism). It's mainly for desktop usage.

The current development philosophy is concerned only with usage on desktop (as
opposed to server) systems.

I just wanted a tool for auto-setting programs' nice in my system, i.e.:

- Why do I get lag, while compiling kernel and playing games?
- Why does dropbox client eat all my IO?
- Why does torrent/dc client make my laptop run slower?
- ...

Use Ananicy to fix your problems!

## Versions

```text
X.Y.Z where
X - Major version,
Y - Script version - reset on each major update
Z - Rules version - reset on each script update
```

Read more about semantic versioning [here](http://semver.org/)

## Dependencies

To use ananicy you must have systemd installed.

- On Debian-based distributions

  ```sh
  sudo apt -y install systemd
  ```

## Installation

- You can install ananicy manually with the following commands:

  ```sh
  git clone https://github.com/Nefelim4ag/Ananicy.git /tmp/ananicy
  cd /tmp/ananicy
  sudo make install
  ```

- ![Arch Linux logo](http://www.monitorix.org/imgs/archlinux.png) Arch:
  [AUR/ananicy-git](https://aur.archlinux.org/packages/ananicy-git)

  ```sh
  yay -S ananicy-git
  ```

- Debian/Ubuntu: Use included script [package.sh](package.sh) in repository root
  directory

  ```sh
  git clone https://github.com/Nefelim4ag/Ananicy.git
  cd Ananicy
  ./package.sh deb
  sudo dpkg -i ./tmp/ananicy-*.deb
  ```

- systemd: Enable the background service (Optional)

  ```sh
  sudo systemctl enable ananicy
  sudo systemctl start ananicy
  ```
  
## Configuration

Rules files should be placed under the `/etc/ananicy.d/` directory and have
`.rules` extensions. Inside the .rules file every process is described in a
separate JSON array; general syntax is described below.

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

All fields except `name` are optional.

'name' used for matching processes can be found using the PID of any running
process _(Replace \<process\> with the name of the executable you wish to create
rules for)_

```sh
basename $(sudo realpath /proc/$(pidof <process>)/exe)
```

Currently matching by other things is not supported.

You can check what Ananicy does with the command:

```sh
ananicy dump proc
```

Ananicy loads all rules in ram while starting, so to apply rules, you must
restart the service.

Available ionice values:

```sh
man ionice
```

## Simple rules for writing rules

CFQ IO Scheduler also uses 'nice' for internal scheduling, so it's mean
processes with same IO class and IO priority, but with different niceness will
take advantages of 'nice' also for IO.

1. Try don't chage 'nice' of system wide process like initrd.
1. Please try use full process name (or name with ^$ symbols like
   NAME=^full_name$)
1. When writing rules - try to only use 'nice', it must be enough in most cases.
1. Don't try to set high priorities! Niceness can fix some performance problems,
   but can give you more, too, if you let it.
   Example: pulseaudio uses 'nice' -11 by default, if you set other cpu hungry
   task, with 'nice' {-20..-12} you can catch a sound glitches.
1. For a CPU-hungry background task like compiling, just use NICE=19.

About IO priority:

1. It's usefull use '{"ioclass": "idle"}' for IO hungry background tasks like:
   file indexers, Cloud Clients, Backups and etc.
1. It's not cool to set realtime to all tasks. The RT scheduling class is given
   first access to the disk, regardless of what else is going on in the system.
   Thus the RT class needs to be used with some care, as it can starve other
   processes. Try to use ioclass first.

## Debugging

Get ananicy output with journalctl:

```shell-session
$ journalctl -efu ananicy.service
```

### Missing `schedtool`

If you see this error in the output

```text
Jan 24 09:44:18 tony-dev ananicy[13783]: ERRO: Missing schedtool! Abort!
```

Fix it in Ubuntu with

```shell
sudo apt install schedtool
```

### Submitting new rules

Please use [pull requests](https://github.com/Nefelim4ag/Ananicy/compare).
Thank you.
