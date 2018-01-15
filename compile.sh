#!/usr/bin/env bash
set -e
source clean.sh
# remove solc from truffle to use our version
rm -rf node_modules/truffle/node_modules/solc
node_modules/.bin/truffle compile --all
