.DEFAULT_GOAL := build
LINUX_TARGET_ENV=GOOS=linux GOARCH=amd64
BUILD=go build
DESTDIR=.

.PHONY: build
build:
	CGO_ENABLED=0 $(LINUX_TARGET_ENV)  $(BUILD) -o $(DESTDIR)/isuride -ldflags "-s -w"
