#!/bin/sh

# Install python3 on Alpine linux (Docker)
if ! [ -v "$(command -v apk)" ]; then
  apk add python3
  exit 0
fi