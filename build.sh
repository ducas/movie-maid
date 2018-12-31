#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "
Usage:   $0 -v <version> -p <push> -l <latest>
Example: $0 -v 0.1.0 -p true -l true
" 1>&2; exit 1; }

declare version=""
declare push="false"
declare latest="false"

while getopts ":v:p:l:" arg; do
  case "${arg}" in
    v) version=${OPTARG} ;;
    p) push=${OPTARG} ;;
    l) latest=${OPTARG} ;;
  esac
done
shift $((OPTIND-1))

if [[ -z "$version" ]]; then
  echo "Version (e.g. 0.1.0):"
  read version
  [[ "${version:?}" ]]
fi
if [[ "$push" != "true" && "$push" != "false" ]]; then
  echo "Push (true|false):"
  read push
  [[ "${push:?}" ]]
fi
if [[ "$latest" != "true" && "$latest" != "false" ]]; then
  echo "Latest (true|false):"
  read latest
  [[ "${latest:?}" ]]
fi

echo "Building movie-maid with version: $version, push: $push, latest: $latest"

type docker >/dev/null 2>&1 || { echo >&2 "Prerequisite missing: docker"; exit 1; }

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

for docker_arch in amd64 arm32v7; do
  case ${docker_arch} in
    amd64   ) qemu_arch="amd64" ;;
    arm32v7 ) qemu_arch="arm" ;;
  esac
  
  cp Dockerfile.template Dockerfile.${docker_arch}
  sed -i "" "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
  sed -i "" "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile.${docker_arch}

  if [ ${docker_arch} == 'amd64' ]; then
    sed -i "" "/__CROSS_/d" Dockerfile.${docker_arch}
  else
    sed -i "" "s/__CROSS_//g" Dockerfile.${docker_arch}
  fi

  docker build -f Dockerfile.${docker_arch} -t "ducas/movie-maid:${version}-${docker_arch}" .
  if [[ "$latest" == "true" ]]; then
    docker tag "ducas/movie-maid:${version}-${docker_arch}" "ducas/movie-maid:latest-${docker_arch}"
    echo "Successfully tagged ducas/movie-maid:latest-${docker_arch}"
  fi

  rm Dockerfile.${docker_arch}
done

if [[ "$push" == "true" ]]; then
  for docker_arch in amd64 arm32v7; do
    docker push "ducas/movie-maid:${version}-${docker_arch}"
    if [[ "$latest" == "true" ]]; then
      docker push "ducas/movie-maid:latest-${docker_arch}"
    fi
  done

  echo "Creating manifest..."
  declare create_manifest="\
  docker manifest create --amend ducas/movie-maid:${version} \
    ducas/movie-maid:${version}-amd64 \
    ducas/movie-maid:${version}-arm32v7"
  if [[ "$latest" == "true" ]]; then
    create_manifest="$create_manifest \
    ducas/movie-maid:latest-amd64 \
    ducas/movie-maid:latest-arm32v7"
  fi
  eval $create_manifest
  echo "Pushing manifest..."
  docker manifest push "ducas/movie-maid:${version}"

  echo "Successfully pushed ducas/movie-maid:${version}"
fi