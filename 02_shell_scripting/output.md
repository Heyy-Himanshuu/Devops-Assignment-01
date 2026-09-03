# Task 2: Shell Scripting – Output

Script: [`shellscript.sh`](./shellscript.sh)

## What the script does

| Requirement | Implementation |
| --- | --- |
| Print current date | `date` |
| Print hostname | `hostname` |
| Print username | `whoami` |
| Print disk usage | `df -h` |
| Print running processes | `ps` |
| Use variables | `variable="Hello, World!"` then `echo "$variable"` |
| Take user input | `read -p "Enter your name: " name` |
| Create a directory | `mkdir -p hello` |
| Create a file | `touch process.log` |
| Output redirection | `echo ... > process.log` then `ps >> process.log` |

## How it was run

The script was executed in a clean Ubuntu container so the process table only contains the
script's own processes (a run directly on the host works the same way, but `ps` there also lists
every other terminal session):

```bash
printf 'Himanshu Rathi\n24BCS10001\n' | docker run -i --rm \
  -v "$PWD:/task" -w /task ubuntu:24.04 bash ./shellscript.sh
```

## Terminal output

```text
Current date and time:
Thu Sep  3 16:29:15 UTC 2026
Hostname: 5d9a96193e61
Username: root
Disk usage:
Filesystem            Size  Used Avail Use% Mounted on
overlay               911G  149G  716G  18% /
tmpfs                  64M     0   64M   0% /dev
shm                    64M     0   64M   0% /dev/shm
/run/host_mark/Users  927G  480G  448G  52% /task
/dev/vda1             911G  149G  716G  18% /etc/hosts
tmpfs                  12G     0   12G   0% /proc/scsi
tmpfs                  12G     0   12G   0% /sys/firmware
Current processes:
  PID TTY          TIME CMD
    1 ?        00:00:00 bash
   10 ?        00:00:00 ps
Hello, World!
My name is Himanshu Rathi
My roll no is 24BCS10001
Saved process information to process.log
```

`read -p` prints its prompt only when stdin is a terminal, so the two prompts do not appear in this
piped transcript — the values read from stdin are echoed back in the last two lines.

## Artefacts created by the script

- `hello/` – directory created with `mkdir`
- [`process.log`](./process.log) – created with `touch`, then filled using `>` and `>>`

```text
Process information:
  PID TTY          TIME CMD
    1 ?        00:00:00 bash
   13 ?        00:00:00 ps
```
