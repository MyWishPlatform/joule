#!/usr/bin/env bash
set -e
node --inspect=0.0.0.0 node_modules/.bin/truffle test "$@"