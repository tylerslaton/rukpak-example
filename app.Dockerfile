# Test and build
FROM golang:1.18 as builder
WORKDIR /build
COPY main.go go.mod Makefile /build/
RUN go mod download
RUN make test-unit
RUN make build

# Start the result of build
FROM gcr.io/distroless/static:debug
WORKDIR /
COPY --from=builder /build/sample-api .
EXPOSE 8080
ENTRYPOINT ["/sample-api"]
