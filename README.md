# DevOps Assignment 1

Solutions for the seven-task DevOps assignment: Linux fundamentals, shell scripting, networking,
Git, Docker, Dockerfiles/images, and Docker networking & storage.

Every command output in this repository was captured from a real run on macOS 15 (Apple Silicon)
with Docker Desktop 29.2.0 — nothing is transcribed from memory.

## Contents

| # | Task | Deliverable |
| --- | --- | --- |
| 1 | Linux Fundamentals | [`01_Linux_Fundamental/learning.md`](./01_Linux_Fundamental/learning.md) |
| 2 | Shell Scripting | [`02_shell_scripting/`](./02_shell_scripting) — [script](./02_shell_scripting/shellscript.sh), [output](./02_shell_scripting/output.md) |
| 3 | Networking Commands | [`03_networking/output.md`](./03_networking/output.md) |
| 4 | Git & GitHub (cherry-pick) | [`04_git/github/output.md`](./04_git/github/output.md) |
| 5 | Docker Fundamentals | [`05_Docker_Fundamental/`](./05_Docker_Fundamental) — 6 apps, [output](./05_Docker_Fundamental/output.md) |
| 6 | Dockerfiles & Images | [`06_DockerFiles_Images/submission.md`](./06_DockerFiles_Images/submission.md) |
| 7 | Docker Networking & Storage | [`07_Docker_Networking/readme.md`](./07_Docker_Networking/readme.md) |

## Task summary

**1. Linux Fundamentals** — soft vs hard links, `adduser` vs `useradd`, `journalctl`, and a command
cheat sheet.

**2. Shell Scripting** — one script covering `date`, `hostname`, `whoami`, `df -h`, `ps`, variables,
`read -p` input, `mkdir`, `touch` and `>` / `>>` redirection into
[`process.log`](./02_shell_scripting/process.log).

**3. Networking Commands** — `ping`, `traceroute`, `netstat`, `nslookup`, `dig`, `telnet` and `curl`,
each with real captured output and an explanation of what the output means.

**4. Git & GitHub** — branching, five commits on a feature branch, and cherry-picking a single
commit onto `main` including resolving the modify/delete conflict it causes.

**5. Docker Fundamentals** — six containerised "Hello World" apps (Nginx, Apache, Node.js, Python,
Java, React), all six built, run and verified with `curl`.

**6. Dockerfiles & Images** — a two-stage Node/Express build, plus a measured size comparison
against the equivalent single-stage image and an explanation of when the technique actually pays off.

**7. Docker Networking & Storage** — three custom bridge networks proving DNS-level isolation,
`host` network mode (and why it behaves differently on macOS), a bind mount updated live, and a real
overlay network with a two-replica swarm service on it.

## Running the Docker tasks

```bash
# Task 5 - six apps
cd 05_Docker_Fundamental
docker build -t nginx-app nginx-app && docker run -d --name nginx-app -p 8081:80 nginx-app
# ... see 05_Docker_Fundamental/output.md for all six

# Task 6 - multi-stage build
cd 06_DockerFiles_Images/multi-stage-app
docker build -t multi-stage-app .
docker run -d -p 8080:3000 --name multi-stage-container multi-stage-app
curl http://localhost:8080
```

Each task's document ends with the cleanup commands for the containers, networks and images it
creates.
