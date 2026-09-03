# Linux Fundamentals – Learning Notes

## Task 1: Soft Link vs Hard Link

A **soft link (symbolic link)** is a separate file that stores the *path* of the target file.

```bash
ln -s original.txt softlink.txt
```

A **hard link** is another directory entry pointing to the *same inode* as the original file.

```bash
ln original.txt hardlink.txt
```

| | Soft link | Hard link |
| --- | --- | --- |
| Points to | File path | Inode (the data itself) |
| Target deleted | Link breaks (dangling) | Link still works |
| Across filesystems | Allowed | Not allowed |
| Directories | Allowed | Not allowed (normally) |
| `ls -l` shows | `link -> target` | An ordinary file |

`ls -li` shows the inode number, which is the quickest way to tell them apart — a hard link shares
the original's inode number, a soft link has its own.

---

## Task 2: `adduser` vs `useradd`

`useradd` is the low-level binary. It creates the account exactly as the flags say and nothing more,
so without `-m` you get a user with no home directory and no password set.

```bash
sudo useradd -m -s /bin/bash testuser
sudo passwd testuser
```

`adduser` is a friendlier Perl wrapper around `useradd` (Debian/Ubuntu). It is interactive, creates
the home directory, copies `/etc/skel`, sets up the user group and prompts for the password.

```bash
sudo adduser testuser
```

**Which is preferred?** On Ubuntu/Debian, `adduser` is preferred for creating users by hand because
it produces a complete, usable account in one step. `useradd` is the right choice in scripts and on
distros where `adduser` is not available, since its behaviour is predictable and non-interactive.

---

## Task 3: `journalctl`

`journalctl` reads the logs collected by `systemd-journald`.

```bash
journalctl                      # everything, oldest first
journalctl -n 20                # last 20 lines
journalctl -f                   # follow live (like tail -f)
journalctl -u ssh               # one unit only
journalctl -u ssh -n 50 --no-pager
journalctl -p err               # priority err and worse
journalctl --since "1 hour ago"
journalctl -b                   # current boot only
journalctl --disk-usage         # how much space the journal uses
```

Useful because it replaces digging through separate files in `/var/log` — the journal is indexed, so
it can be filtered by unit, priority, time window and boot.

---

## Task 4: Linux Command Cheat Sheet

| Command | Purpose |
| --- | --- |
| `pwd` | Print the current working directory |
| `ls` | List directory contents (`-l` long, `-a` hidden, `-h` human sizes) |
| `cd` | Change directory |
| `mkdir` | Create a directory (`-p` for nested) |
| `touch` | Create an empty file / update its timestamp |
| `cp` | Copy files (`-r` for directories) |
| `mv` | Move or rename |
| `rm` | Delete files (`-r` recursive, `-f` force) |
| `cat` | Print a file's contents |
| `less` | Page through a file |
| `head` / `tail` | First / last lines (`tail -f` to follow) |
| `grep` | Search text by pattern (`-r` recursive, `-i` ignore case) |
| `find` | Search the filesystem by name, type, size, mtime |
| `chmod` | Change permissions |
| `chown` | Change owner and group |
| `ln` | Create links (`-s` for symbolic) |
| `ps` | Snapshot of running processes (`ps aux`) |
| `top` / `htop` | Live process and resource monitor |
| `kill` | Send a signal to a process (`-9` to force) |
| `df` | Free disk space per filesystem (`-h`) |
| `du` | Disk used by files/directories (`-sh *`) |
| `free` | Memory usage (`-h`) |
| `tar` | Create/extract archives (`-czf`, `-xzf`) |
| `systemctl` | Start/stop/enable/inspect services |
| `journalctl` | Read systemd logs |
| `sudo` | Run a command as another user (usually root) |

## Conclusion

These four tasks cover the basics of how Linux links files, how user accounts are created, how
`systemd` exposes logs, and the day-to-day command set used to move around and inspect a machine.
