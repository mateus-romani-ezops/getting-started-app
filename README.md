# Getting started

This repository is a sample application for users following the getting started guide at https://docs.docker.com/get-started/.

The application is based on the application from the getting started tutorial at https://github.com/docker/getting-started

---

# Building the Docker Image

## Creating a Dockerfile
After creating the Dockerfile in the same locations as the `package.json` file, the first block of code to add is:

```Dockerfile
FROM node:lts-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node", "src/index.js"]
EXPOSE 3000
```

- `FROM node:lts-alpine` specifies the base image to use for the application;
- `WORKDIR /app` sets the working directory inside the container to `/app`;
- `COPY . .` copies the contents of the current directory on the host machine to the working directory in the container;
- `RUN yarn install --production` installs the application dependencies defined in the `package.json` file;
- `CMD ["node", "src/index.js"]` specifies the command to run the application when the container starts;
- `EXPOSE 3000` indicates that the application listens on port 3000.
---

## Building the Image
To build the Docker image, run the following command in the terminal from the directory containing the Dockerfile:

```bash
docker build -t getting-started .
```

This command builds the Docker image and tags it as `getting-started` using the `-t` flag.