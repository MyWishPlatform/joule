#!/usr/bin/env bash
set -e
source clean.sh
cp -R node_modules/ethereum-alarm-clock/contracts/ .
node node_modules/.bin/truffle compile