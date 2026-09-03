# Task 3: Networking Commands – Output

Every transcript below is real output captured while doing this task.

`traceroute` was run on the host, because Docker Desktop NATs container traffic through a VM and
drops the UDP probes (`2 * * *` onwards). The rest were run inside a
[`nicolaka/netshoot`](https://github.com/nicolaka/netshoot) container, which ships all of these
tools and keeps the captured `netstat` output limited to the container's own sockets:

```bash
docker run --rm -it nicolaka/netshoot
```

---

## 1. `ping` – is the host reachable, and how fast?

Sends ICMP echo requests and reports round-trip time and packet loss.

```console
$ ping -c 4 google.com
PING google.com (142.250.206.110) 56(84) bytes of data.
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=1 ttl=63 time=56.3 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=2 ttl=63 time=93.3 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=3 ttl=63 time=22.7 ms
64 bytes from lcboma-az-in-f14.1e100.net (142.250.206.110): icmp_seq=4 ttl=63 time=29.0 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3014ms
rtt min/avg/max/mdev = 22.701/50.326/93.336/27.860 ms
```

`0% packet loss` means the path is healthy; `ttl=63` and the ~22–93 ms spread show a few hops away
over a shared Wi-Fi link.

---

## 2. `traceroute` – which hops does the traffic take?

Sends packets with an increasing TTL, so each router along the path reveals itself.

```console
$ traceroute -m 12 google.com
traceroute to google.com (142.250.206.110), 12 hops max, 40 byte packets
 1  wifi.height8tech.com (10.114.0.1)  18.898 ms  5.852 ms  7.942 ms
 2  202.131.133.17.convergentindia.com (202.131.133.17)  6.596 ms  7.515 ms  6.452 ms
 3  115.117.125.189.static-mumbai.vsnl.net.in (115.117.125.189)  20.395 ms  9.224 ms  9.747 ms
 4  * 172.28.117.90 (172.28.117.90)  14.337 ms *
 5  115.112.15.114.static-chennai.vsnl.net.in (115.112.15.114)  13.915 ms  13.660 ms  12.481 ms
 6  * * *
 7  142.251.55.226 (142.251.55.226)  14.730 ms
    142.251.60.184 (142.251.60.184)  12.596 ms
    142.251.55.64 (142.251.55.64)  14.127 ms
 8  142.251.51.118 (142.251.51.118)  12.499 ms
    172.253.71.2 (172.253.71.2)  14.415 ms  95.472 ms
 9  * 142.251.241.173 (142.251.241.173)  26.304 ms *
10  192.178.254.30 (192.178.254.30)  24.272 ms
    192.178.254.224 (192.178.254.224)  40.708 ms
    142.250.213.170 (142.250.213.170)  24.370 ms
11  192.178.110.109 (192.178.110.109)  26.333 ms  28.383 ms
    72.14.232.79 (72.14.232.79)  25.895 ms
12  142.250.210.183 (142.250.210.183)  26.409 ms
    142.250.212.171 (142.250.212.171)  36.273 ms  26.670 ms
```

Reading the path: hop 1 is the local gateway, hops 2–5 are the ISP, and from hop 7 the addresses
belong to Google's network. `* * *` means that router did not reply to the probe (usually ICMP is
rate-limited or filtered) — it does not mean the path is broken, since later hops still answer.

---

## 3. `netstat` – what sockets and routes exist?

```console
$ netstat -tuln                        # -t tcp  -u udp  -l listening  -n numeric
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN
```

```console
$ netstat -rn                          # routing table
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
```

The listener on `0.0.0.0:8080` is a `nc -l -p 8080` started for the demo. The routing table shows
the container's default route pointing at the Docker bridge gateway `172.17.0.1`.

---

## 4. `nslookup` – simple DNS lookup

```console
$ nslookup github.com
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	github.com
Address: 20.207.73.82
```

`Server:` is the resolver that answered (Docker Desktop's internal DNS). *Non-authoritative* means
the answer came from a cache rather than from GitHub's own nameservers.

---

## 5. `dig` – detailed DNS lookup

```console
$ dig google.com +noall +answer
google.com.		330	IN	A	142.250.206.110
```

```console
$ dig google.com MX +short
10 smtp.google.com.
```

`dig` is the tool to reach for when the record type or the TTL matters: `330` is the remaining TTL
in seconds, `IN A` is an IPv4 address record, and `MX` returns mail exchangers with their priority.

---

## 6. `telnet` – is a TCP port open?

Its practical use is checking reachability of a specific port.

```console
$ telnet web-telnet 80        # port open
Connected to web-telnet

$ telnet web-telnet 3306      # port closed
telnet: can't connect to remote host (172.18.0.2): Connection refused
```

`Connected to ...` is the TCP handshake succeeding; `Connection refused` means nothing is listening
on that port. `web-telnet` is an `nginx:alpine` container started on a user-defined Docker network
for this check.

Typing a request by hand through `telnet` is awkward because the client rewrites line endings, so
`nc` is the better choice for a raw HTTP exchange:

```console
$ printf "GET / HTTP/1.1\r\nHost: web-telnet\r\nConnection: close\r\n\r\n" | nc web-telnet 80
HTTP/1.1 200 OK
Server: nginx/1.31.5
Date: Thu, 03 Sep 2026 16:35:10 GMT
Content-Type: text/html
Content-Length: 896
Last-Modified: Wed, 02 Sep 2026 17:23:39 GMT
Connection: close
ETag: "6a985b9b-380"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

---

## 7. `curl` – make an HTTP request

```console
$ curl -sI https://example.com          # -I = headers only
HTTP/2 200
date: Thu, 03 Sep 2026 16:33:42 GMT
content-type: text/html
server: cloudflare
last-modified: Sun, 30 Aug 2026 04:11:49 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 753
cf-cache-status: HIT
cf-ray: a35628620ba4c87a-MAA
```

```console
$ curl -s https://api.github.com/zen
It's not fully shipped until it's fast.
```

`HTTP/2 200` is the status line, and `cf-cache-status: HIT` shows the response was served from
Cloudflare's cache.

---

## Summary

| Command | Layer | Answers the question |
| --- | --- | --- |
| `ping` | ICMP | Is the host up, and what is the latency? |
| `traceroute` | ICMP/UDP | Which routers is the traffic passing through? |
| `netstat` | TCP/UDP | What is listening, connected, and how is traffic routed? |
| `nslookup` | DNS | What IP does this name resolve to? |
| `dig` | DNS | Full record detail — type, TTL, authority |
| `telnet` | TCP | Is this specific port open? |
| `curl` | HTTP | What does the server actually return? |
