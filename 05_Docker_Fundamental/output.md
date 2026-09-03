# Task 5: Docker Fundamentals – Output

Six single-container "Hello World" apps, one per stack. Each folder holds the application source and
its `Dockerfile`.

| App | Folder | Base image | Container port | Host port | Image size |
| --- | --- | --- | --- | --- | --- |
| Nginx | [`nginx-app`](./nginx-app) | `nginx:alpine` | 80 | 8081 | 102 MB |
| Apache | [`Apache-app`](./Apache-app) | `httpd:2.4` | 80 | 8082 | 205 MB |
| Node.js | [`nodejs-app`](./nodejs-app) | `node:20-alpine` | 3000 | 3000 | 194 MB |
| Python | [`python-app`](./python-app) | `python:3.12-slim` | 8000 | 8000 | 214 MB |
| Java | [`java-app`](./java-app) | `eclipse-temurin:21-jdk` | 8080 | 8080 | 744 MB |
| React | [`React-app`](./React-app) | `node:20-alpine` | 5173 | 5173 | 411 MB |

Nginx and Apache use 8081/8082 on the host so they do not clash with the Java app on 8080.

## Build and run

```bash
docker build -t nginx-app  nginx-app  && docker run -d --name nginx-app  -p 8081:80   nginx-app
docker build -t apache-app Apache-app && docker run -d --name apache-app -p 8082:80   apache-app
docker build -t nodejs-app nodejs-app && docker run -d --name nodejs-app -p 3000:3000 nodejs-app
docker build -t python-app python-app && docker run -d --name python-app -p 8000:8000 python-app
docker build -t java-app   java-app   && docker run -d --name java-app   -p 8080:8080 java-app
docker build -t react-app  React-app  && docker run -d --name react-app  -p 5173:5173 react-app
```

## All six containers running

```console
$ docker ps
NAMES        IMAGE        STATUS          PORTS
react-app    react-app    Up 25 seconds   0.0.0.0:5173->5173/tcp, [::]:5173->5173/tcp
java-app     java-app     Up 25 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
python-app   python-app   Up 26 seconds   0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp
nodejs-app   nodejs-app   Up 26 seconds   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
apache-app   apache-app   Up 26 seconds   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp
nginx-app    nginx-app    Up 26 seconds   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
```

```console
$ docker images
REPOSITORY   TAG      SIZE
react-app    latest   411MB
java-app     latest   744MB
python-app   latest   214MB
nodejs-app   latest   194MB
apache-app   latest   205MB
nginx-app    latest   102MB
```

## Verifying each app

```console
$ curl -s http://localhost:8081      # nginx
<h1>Hello World</h1>

$ curl -s http://localhost:8082      # apache
<h1>Hello World</h1>

$ curl -s http://localhost:3000      # node.js
<h1>Hello World</h1>

$ curl -s http://localhost:8000      # python
<h1>Hello World</h1>

$ curl -s http://localhost:8080      # java
<h1>Hello World</h1>
```

The React app is served by the Vite dev server, so the HTML shell arrives first and React renders
`<h1>Hello World</h1>` into `<div id="root">` on the client:

```console
$ curl -s http://localhost:5173      # react
<!doctype html>
<html lang="en">
  <head>
    <script type="module">import { injectIntoGlobalHook } from "/@react-refresh";
injectIntoGlobalHook(window);
window.$RefreshReg$ = () => {};
window.$RefreshSig$ = () => (type) => type;</script>

    <script type="module" src="/@vite/client"></script>

    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
```

## Notes

- **Nginx / Apache** need no runtime — the base image already serves static files, so the Dockerfile
  is just `FROM` + `COPY` + `EXPOSE` and inherits the base image's `CMD`.
- **`-alpine` and `-slim` tags** were chosen over the full images to keep the layers small; the same
  Dockerfiles work with `node:20` or `python:3.12`, just several hundred MB larger.
- **The servers bind to `0.0.0.0`**, not `127.0.0.1`. Binding to loopback inside a container makes
  the port unreachable through `-p`, since the published port forwards to the container's external
  interface.
- **`EXPOSE` is documentation only.** It records the port the image intends to use; `-p` is what
  actually publishes it to the host.
- **The Java image is the largest** because it ships a full JDK to run `javac` at build time. Task 6
  fixes exactly this problem with a multi-stage build.

## Cleanup

```bash
docker rm -f nginx-app apache-app nodejs-app python-app java-app react-app
```
