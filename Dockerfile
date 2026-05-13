ARG GO_IMAGE=rancher/hardened-build-base:v1.25.10b1
FROM ${GO_IMAGE} AS builder

RUN set -x && \
    apk --no-cache add \
    file \
    git \
    make \
    ca-certificates

ARG SRC=github.com/helm/helm
ARG TAG=v4.1.4
ARG TARGETARCH

RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${SRC}
WORKDIR $GOPATH/src/${SRC}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}

RUN MODULE_PATH=$(go list -m) && \
    GO_LDFLAGS="-X ${MODULE_PATH}/internal/version.version=${TAG} \
    -X ${MODULE_PATH}/internal/version.metadata= \
    -X ${MODULE_PATH}/internal/version.gitCommit=$(git rev-parse HEAD) \
    -X ${MODULE_PATH}/internal/version.gitTreeState=clean" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/helm ./cmd/helm
RUN go-assert-static.sh bin/helm
RUN if [ "${TARGETARCH}" = "amd64" ]; then \
        go-assert-boring.sh bin/helm ; \
    fi
RUN install -s bin/helm /usr/local/bin
RUN helm version --template='{{.Version}}'

FROM scratch
LABEL org.opencontainers.image.source="https://github.com/cwayne18/image-build-helm"
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
