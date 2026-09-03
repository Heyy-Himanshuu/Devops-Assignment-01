# Task 6: Dockerfiles & Images – Multi-Stage Build

## Name

Himanshu Rathi

## Roll No

<!-- Replace with your actual roll number before submitting. -->
`<your-roll-no>`

---

## Task 1: Multi-Stage Docker Build

The app is the Node/Express "Hello World" service from the course repo
([`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros), at
`session6-7-docker/multi-stage-dockerfile`). It is copied into
[`multi-stage-app/`](./multi-stage-app) as ordinary files so this repository is self-contained and
can be built without cloning anything else.

### The Dockerfile

[`multi-stage-app/Dockerfile`](./multi-stage-app/Dockerfile):

```dockerfile
# Stage 1: Build
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production
FROM node:24-alpine AS production
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/server.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

Stage 1 installs **all** dependencies and holds the full source tree. Stage 2 starts from a clean
base and copies in only what is needed at runtime — the manifest, the production-only
`node_modules`, and `server.js`. Everything else from stage 1 is discarded.

### Build and run

```bash
docker build -t multi-stage-app .
docker run -d -p 8080:3000 --name multi-stage-container multi-stage-app
```

```console
$ docker ps
CONTAINER ID   IMAGE             STATUS         PORTS                                         NAMES
6dac9d6e5217   multi-stage-app   Up 4 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   multi-stage-container
```

```console
$ docker logs multi-stage-container

> docker-hello-world@1.0.0 start
> node server.js

Server running on port 3000
```

### Application output

The app was accessed at <http://localhost:8080>:

```console
$ curl http://localhost:8080
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

---

## Task 2: Image Size Comparison

To measure what the second stage actually saves,
[`Dockerfile.single`](./multi-stage-app/Dockerfile.single) builds the same app in one stage:

```bash
docker build -f Dockerfile.single -t single-stage-app .
```

```console
$ docker images
REPOSITORY        TAG      SIZE
multi-stage-app   latest   243MB
single-stage-app  latest   249MB
```

**The saving here is only ~6 MB (about 2%), and that is worth being honest about.** This app has no
dev dependencies, no compile step and no build artefacts, so there is very little for the second
stage to leave behind — just the npm cache and the dev-dependency tree that `--omit=dev` skips.

Where multi-stage builds actually pay off is when the build needs a toolchain that the runtime does
not:

| Case | Single-stage | Multi-stage | Why |
| --- | --- | --- | --- |
| React/Vite app | ~400 MB (Node + `node_modules` + sources) | ~50 MB (`nginx` + `dist/`) | Node is a build tool, not a runtime |
| Go binary | ~800 MB (full Go toolchain) | ~10 MB (`scratch` + binary) | The compiler is not needed to run |
| Java app | ~744 MB (JDK, as in [task 5](../05_Docker_Fundamental)) | ~200 MB (JRE + jar) | `javac` is build-time only |

The [java-app in task 5](../05_Docker_Fundamental/java-app) is a concrete example from this same
assignment: it ships a whole JDK (744 MB) purely so `javac` can run at build time.

### What the layers look like

`docker history` confirms the final image only contains the runtime pieces — no source tree, no dev
dependencies, and `npm install --omit=dev` contributing just 9.45 MB:

```console
$ docker history multi-stage-app
CREATED BY                                      SIZE
CMD ["npm" "start"]                             0B
EXPOSE [3000/tcp]                               0B
COPY /app/server.js ./ # buildkit               12.3kB
RUN /bin/sh -c npm install --omit=dev # buil…   9.45MB
COPY /app/package*.json ./ # buildkit           45.1kB
WORKDIR /app                                    8.19kB
```

---

## Takeaways

- Each `FROM` starts a new stage; only what is `COPY --from`'d survives into the final image.
- Naming stages (`AS builder`, `AS production`) makes the intent readable and lets you target one
  stage directly with `docker build --target builder`.
- `COPY package*.json ./` before `COPY . .` is deliberate: dependency layers are then cached and
  only re-run when the manifest changes, not on every source edit.
- The size benefit is proportional to how much of the build toolchain the runtime does not need —
  large for compiled languages and bundlers, small for a plain Node service like this one.

## Cleanup

```bash
docker rm -f multi-stage-container
docker rmi multi-stage-app single-stage-app
```
