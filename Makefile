.PHONY: build test run lint clean

build:
	go build -o bin/go-hello .

test:
	go test -v -race ./...

run:
	go run .

lint:
	go vet ./...

clean:
	rm -rf bin/
