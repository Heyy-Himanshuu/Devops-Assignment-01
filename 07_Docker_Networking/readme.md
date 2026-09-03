# Task 7: Docker Networking & Storage

All transcripts below are real output captured while doing this task, on Docker Desktop 29.2.0
(macOS, Apple Silicon).

---

## Task 1: Custom bridge networks and container-to-container DNS

Three user-defined bridge networks, with each container attached only to the networks it needs:

```console
$ docker network create frontend-net
bf4689b79e2574657bd7002bc7b5f4e5fb60c33e8ae41fe31652b36c9cac88cf
$ docker network create backend-net
b4a7b35a82af5eace37e754c20569af3ba434d27f8cb370c194514fd634096e7
$ docker network create db-net
41cb65377972df72badd11d23e3e86785a0c136002fdaf94bb463bfe63617ff0
```

```console
$ docker run -d --name frontend --network frontend-net nginx:alpine
32892a36be51d542536e296b599d333cb79dce654aecb9f46e2fb807f8e88f95

$ docker run -d --name backend --network frontend-net alpine \
    sh -c "apk add --no-cache iputils && sleep infinity"
43e45e64c3e140cdc62fe6a2c48c26b4076cc6402138125341b650943a7a4748

$ docker network connect backend-net backend

$ docker run -d --name database --network backend-net -e MYSQL_ROOT_PASSWORD=root mysql:8
6b03485b510235cc708e80673a5d5bc7680bd227fc32fddaf82fa4b4a65bcc69

$ docker network connect db-net database
```

Which container sits on which network:

```console
$ docker inspect frontend --format '{{json .NetworkSettings.Networks}}'   # keys only
['frontend-net']
$ docker inspect backend  --format '{{json .NetworkSettings.Networks}}'
['backend-net', 'frontend-net']
$ docker inspect database --format '{{json .NetworkSettings.Networks}}'
['backend-net', 'db-net']
```

```text
frontend-net          backend-net           db-net
┌──────────┐          ┌──────────┐          ┌──────────┐
│ frontend │          │          │          │          │
│ backend  │──────────│ backend  │          │          │
│          │          │ database │──────────│ database │
└──────────┘          └──────────┘          └──────────┘
```

`backend` is the only path from `frontend` to `database` — exactly the three-tier shape this task is
asking for.

### Verifying DNS resolution

Docker runs an embedded DNS server on user-defined networks, so containers resolve each other **by
container name** — but only across a network they *share*:

```console
# frontend and backend share frontend-net
$ docker exec frontend getent hosts backend
172.19.0.3        backend  backend
$ docker exec backend getent hosts frontend
172.19.0.2        frontend  frontend

# backend and database share backend-net
$ docker exec backend getent hosts database
172.20.0.3        database  database

# frontend and database share NO network -> resolution fails
$ docker exec frontend getent hosts database
(exit 2 - name not resolved, as expected)
```

That failure is the important result: isolation on a user-defined bridge is real, and it applies at
DNS level before it ever gets to packet filtering.

```console
$ docker exec backend ping -c 3 frontend
PING frontend (172.19.0.2) 56(84) bytes of data.
64 bytes from frontend.frontend-net (172.19.0.2): icmp_seq=1 ttl=64 time=0.235 ms
64 bytes from frontend.frontend-net (172.19.0.2): icmp_seq=2 ttl=64 time=0.139 ms
64 bytes from frontend.frontend-net (172.19.0.2): icmp_seq=3 ttl=64 time=0.179 ms

--- frontend ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2048ms
```

Note `frontend.frontend-net` in the reply — the network name becomes the DNS search domain. Each
network also gets its own subnet:

```console
$ docker network inspect backend-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'
backend 172.20.0.2/16
database 172.20.0.3/16
```

> The **default** `bridge` network behaves differently: containers there get IPs but **no** name
> resolution. Automatic DNS is a feature of *user-defined* networks only.

---

## Task 2: Host network mode

```console
$ docker run -d --name apache-host --network host httpd:2.4
06e578527060104208182d51958049a80b1686159eb112d7f77a151faf5ee05d

$ docker ps --filter name=apache-host
IMAGE       STATUS         PORTS     NAMES
httpd:2.4   Up 3 seconds             apache-host
```

The `PORTS` column is empty — with `--network host` there is no port mapping, because the container
shares the host's network namespace directly. That also means `-p` is ignored.

On Linux, `curl http://localhost:80` on the host would now hit Apache. On macOS it does not:

```console
$ curl -sI --max-time 5 http://localhost:80
curl: (7) Failed to connect to localhost port 80: Connection refused
```

**This is not a failure — it is the Docker Desktop VM boundary.** The daemon runs inside a Linux VM,
so "host" means *the VM*, not the Mac. Apache really is listening on the VM's network namespace,
which another `--network host` container can prove:

```console
$ docker run --rm --network host nicolaka/netshoot curl -sI http://localhost:80
HTTP/1.1 200 OK
Date: Thu, 03 Sep 2026 16:43:00 GMT
Server: Apache/2.4.68 (Unix)
Last-Modified: Fri, 07 Nov 2025 08:23:08 GMT
ETag: "bf-642fce432f300"
Accept-Ranges: bytes
Content-Length: 191
Content-Type: text/html
```

```console
$ docker logs apache-host | tail -2
[Thu Sep 03 16:42:44.052428 2026] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache/2.4.68 (Unix) configured -- resuming normal operations
[Thu Sep 03 16:42:44.052612 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'
```

| | `bridge` (default) | `host` |
| --- | --- | --- |
| Network namespace | Its own | Shared with the host |
| Port publishing | Needs `-p` | None; binds host ports directly |
| Port conflicts | Isolated per container | Two containers cannot share a port |
| Container-name DNS | Yes (user-defined networks) | No |
| Performance | Slight NAT overhead | No NAT overhead |
| Works on macOS/Windows | Yes | Only inside the VM |

---

## Task 3: Bind mount

A bind mount maps a host directory straight into the container, so edits on the host are visible
immediately — no rebuild, no restart.

```console
$ echo "Hello students" > index.html

$ docker run -d --name nginx-bind -p 8085:80 -v "$(pwd):/usr/share/nginx/html" nginx:alpine
b827bc0d596ff2a20eac95f045418382658da6abdfdca2a3f5b4c4ad20866db8

$ curl http://localhost:8085
Hello students
```

Now edit the file on the **host**, without touching the container:

```console
$ echo "Hello students - Updated" > index.html

$ curl http://localhost:8085
Hello students - Updated

$ docker exec nginx-bind cat /usr/share/nginx/html/index.html
Hello students - Updated
```

```console
$ docker inspect nginx-bind --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}'
bind /Users/.../07_Docker_Networking/bind-mount -> /usr/share/nginx/html
```

The served file is [`bind-mount/index.html`](./bind-mount/index.html).

> Immediately after the write, one request still returned the old body — nginx caches open file
> descriptors, and on macOS the file-sharing layer adds a moment of latency. The next request
> served the new content.

### Bind mount vs named volume

| | Bind mount (`-v /host/path:/container/path`) | Named volume (`-v myvol:/container/path`) |
| --- | --- | --- |
| Lives at | A path you choose on the host | Docker-managed area (`/var/lib/docker/volumes`) |
| Best for | Local development, live source editing | Databases, production state |
| Portability | Tied to the host's directory layout | Portable; Docker owns the lifecycle |
| Host visibility | Directly editable | Only via Docker |

---

## Task 4: Overlay network

An **overlay network** spans multiple Docker hosts. Docker builds a VXLAN tunnel between the daemons
so containers on different physical machines share one virtual L2 network and can talk by container
or service name, as if they were on the same bridge.

It is the standard networking driver for **Docker Swarm**, which is why it requires swarm mode:

```console
$ docker network create -d overlay my-overlay
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or
"docker swarm join" to connect this node to swarm and try again.
```

```console
$ docker swarm init
Swarm initialized: current node (22vrctin30gwixxsc789hna1o) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token <redacted-join-token> 192.168.65.3:2377
```

```console
$ docker network create -d overlay --attachable my-overlay
iatv5vtqoodf1t47lw4n9viya

$ docker network ls
NAME           DRIVER    SCOPE
ingress        overlay   swarm
my-overlay     overlay   swarm
```

Two things to notice: the `SCOPE` is `swarm`, not `local` — the network definition is stored in the
swarm's raft state and exists on every node — and `ingress` was created automatically to handle
routing-mesh traffic for published service ports.

`--attachable` is what allows plain `docker run` containers (not just swarm services) to join:

```console
$ docker run -d --name ov-web --network my-overlay nginx:alpine
a7ef8bd6fcd2fc304541be5b7f33b8a348a0a9c549c625072a48e5b3fb22a0b3
$ docker run -d --name ov-client --network my-overlay alpine sleep infinity
eb418c380e5a201826d96cf83a88e4d9d7a66214a4f055535d3ed9dfe42ffbd0

$ docker exec ov-client getent hosts ov-web
10.0.1.2          ov-web  ov-web

$ docker exec ov-client wget -qO- http://ov-web
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

The `10.0.x.x` address is the overlay's own subnet, separate from the `172.x` bridge subnets used in
task 1.

```console
$ docker network inspect my-overlay --format '{{.Driver}} / {{.Scope}} / attachable={{.Attachable}}'
overlay / swarm / attachable=true
```

### A replicated service on the overlay

```console
$ docker service create --name web-svc --network my-overlay --replicas 2 -p 8086:80 nginx:alpine
verify: Service i49lcxepualb062z1twbr59xi converged

$ docker service ls
ID             NAME      MODE         REPLICAS   IMAGE          PORTS
i49lcxepualb   web-svc   replicated   2/2        nginx:alpine   *:8086->80/tcp

$ docker service ps web-svc
NAME        NODE             CURRENT STATE
web-svc.1   docker-desktop   Running 11 seconds ago
web-svc.2   docker-desktop   Running 11 seconds ago

$ curl -sI http://localhost:8086
HTTP/1.1 200 OK
Server: nginx/1.31.5
Date: Thu, 03 Sep 2026 16:43:51 GMT
Content-Type: text/html
```

`*:8086->80/tcp` is the routing mesh: the port is published on **every** swarm node, and a request
arriving at any node is load-balanced to a healthy replica wherever it happens to run. Both replicas
land on `docker-desktop` here because this is a single-node swarm; on a real multi-node cluster the
overlay is what lets those replicas reach each other across machines.

### When to use which driver

| Driver | Scope | Use it for |
| --- | --- | --- |
| `bridge` | Single host | Normal multi-container apps on one machine |
| `host` | Single host | Removing NAT overhead; binding host ports directly |
| `overlay` | Multi-host | Swarm services; containers spread across machines |
| `macvlan` | Single host | Giving a container its own MAC/IP on the physical LAN |
| `none` | — | Fully disabling networking |

---

## Cleanup

```bash
# task 1-3
docker rm -f frontend backend database nginx-bind apache-host
docker network rm frontend-net backend-net db-net

# task 4
docker service rm web-svc
docker rm -f ov-web ov-client
docker network rm my-overlay
docker swarm leave --force
```
