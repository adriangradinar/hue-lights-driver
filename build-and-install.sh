#!/bin/bash

#!/usr/bin/env bash

function red {
  echo "\033[0;31m${1}\033[0m"
}

function green {
  echo "\033[0;32m${1}\033[0m"
}

function datef
{
  date +'%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(datef) $ME]: $@"
}

err() {
  echo "[$(datef) $ME]: $@" >&2
}

die() {
  rc=$1
  shift
  err "$@"
  exit $rc
}

assert_or_die() {
  if [[ "$1" != "$2" ]]
  then
    die 1 "ERROR: ${3}"
  fi
}

function fail {
    echo -e "[$(datef) $ME]: ${1} \nERROR: ${2} $(red FAILED)"
    exit 1
}

function success {
    echo -e "[$(datef) $ME]: ${1} $(green OK)"
}

function test_assert {
  if [ "$1" != "$2" ]
  then
    fail "$3" "$1"
  else
    success "$3"
  fi
}

seedManifest() {
  log "Uploading Manifest for ${1} ..."
  STATUS=$(curl --insecure --cookie-jar ./databox-jar -sL -w "%{http_code}\\n" https://127.0.0.1:8181/ -o /dev/null)
  test_assert ${STATUS} 200 "Seeding manifest"

  PAYLOAD=$(<${1}/databox-manifest.json)
  PAYLOAD="manifest=${PAYLOAD}"

  EXPECTED='{"success":true}'
  RES=$(curl --insecure --cookie ./databox-jar -s -X POST -d "${PAYLOAD}" -L 'https://127.0.0.1:8181/app/post')
  test_assert ${RES} ${EXPECTED} "Uploading manifest"

  rm ./databox-jar
}

VERSION=$(cat ../Version)

docker pull databoxsystems/core-store:${VERSION}
docker tag databoxsystems/core-store:${VERSION} core-store:${VERSION}
docker pull databoxsystems/core-store:latest
docker tag databoxsystems/core-store:latest core-store:latest

cd driver
docker build -t example-driver -t example-driver:${VERSION} .
cd ..
seedManifest driver


