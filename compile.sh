#!/usr/bin/env bash
set -e
source clean.sh
node_modules/.bin/truffle compile --all
