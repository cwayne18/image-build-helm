# rancher/hardened-helm

This repository creates a hardened binary image of [Helm](https://github.com/helm/helm) and deploys it in a scratch image.

## Build

```sh
TAG=v4.1.4 make image-build
```
