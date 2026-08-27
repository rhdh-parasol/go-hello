FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /go-hello .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
COPY --from=builder /go-hello /usr/local/bin/go-hello
EXPOSE 8080
ENTRYPOINT ["go-hello"]
