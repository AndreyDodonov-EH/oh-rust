#!/bin/bash
# _oh-rust-debug.sh

# Build the Rust compiler (stage 2 means just build it with the installed compiler)
./x.py build --stage 1 library
rustup toolchain link stage1 build/host/stage1
rustup default stage1
