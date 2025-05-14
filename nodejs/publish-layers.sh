#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_DIR=nodejs
DIST_DIR=dist

source ../libBuild.sh

function usage {
  	echo "./publish-layers.sh [build-16|build-18|build-20|build-22|publish-16|publish-18|publish-20|publish-22]"
}

function make_package_json {
cat <<EOM >fake-package.json
{
  "name": "newrelic-esm-lambda-wrapper",
  "type": "module"
}
EOM
}

function build_wrapper {
  node_version=$1
  arch=$2
  echo "Building new relic layer for nodejs${node_version}.x (${arch})"
  ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.zip
  rm -rf $BUILD_DIR $ZIP
  mkdir -p $DIST_DIR

  mkdir -p $BUILD_DIR
  cp package.json $BUILD_DIR/
  cp package-lock.json $BUILD_DIR/ || true
  npm install --omit=dev --prefix $BUILD_DIR

  NEWRELIC_AGENT_VERSION=$(npm list newrelic --prefix $BUILD_DIR | grep newrelic@ | grep -v deduped | awk -F '@' '{print $2}' | head -n1)
  touch $DIST_DIR/nr-env
  echo "NEWRELIC_AGENT_VERSION=$NEWRELIC_AGENT_VERSION" > $DIST_DIR/nr-env

  mkdir -p $BUILD_DIR/node_modules/newrelic-lambda-wrapper
  cp index.js $BUILD_DIR/node_modules/newrelic-lambda-wrapper
  mkdir -p $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper
  cp esm.mjs $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/index.js
  make_package_json
  cp fake-package.json $BUILD_DIR/node_modules/newrelic-esm-lambda-wrapper/package.json

  download_extension $arch

  zip -rq $ZIP $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE

  rm -rf fake-package.json $BUILD_DIR $EXTENSION_DIST_DIR $EXTENSION_DIST_PREVIEW_FILE

  echo "Build complete: ${ZIP}"
}

function publish_wrapper {
  node_version=$1
  arch=$2
  ZIP=$DIST_DIR/nodejs${node_version}x.${arch}.zip
  source $DIST_DIR/nr-env
  if [ ! -f $ZIP ]; then
    echo "Package not found: ${ZIP}"
    exit 1
  fi

  for region in "${REGIONS_ARM[@]}"; do
    publish_layer $ZIP $region nodejs${node_version}.x ${arch} $NEWRELIC_AGENT_VERSION
  done
}

case "$1" in
"build_wrapper")
  build_wrapper $2 $3
  ;;
"publish_wrapper")
  publish_wrapper $2 $3
  ;;
"build-16")
  build_wrapper 16 arm64 
  build_wrapper 16 x86_64 
	;;
"publish-16")
  publish_wrapper 16 arm64
  publish_wrapper 16 x86_64 
	;;
"build-18")
  build_wrapper 18 arm64 
  build_wrapper 18 x86_64 
	;;
"publish-18")
  publish_wrapper 18 arm64
  publish_wrapper 18 x86_64 
	;;  
"build-20")
  build_wrapper 20 arm64 
  build_wrapper 20 x86_64 
	;;
"publish-20")
  publish_wrapper 20 arm64
  publish_wrapper 20 x86_64 
	;;
"build-22")
  build_wrapper 22 arm64 
  build_wrapper 22 x86_64 
	;;
"publish-22")
  publish_wrapper 22 arm64
  publish_wrapper 22 x86_64 
	;;
"build-publish-16-ecr-image")
  build_wrapper 16 arm64 
	publish_docker_ecr $DIST_DIR/nodejs16x.arm64.zip nodejs16.x arm64
  build_wrapper 16 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs16x.x86_64.zip nodejs16.x x86_64
	;;
"build-publish-18-ecr-image")
  build_wrapper 18 arm64 
	publish_docker_ecr $DIST_DIR/nodejs18x.arm64.zip nodejs18.x arm64
  build_wrapper 18 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs18x.x86_64.zip nodejs18.x x86_64
	;;  
"build-publish-20-ecr-image")
  build_wrapper 20 arm64 
	publish_docker_ecr $DIST_DIR/nodejs20x.arm64.zip nodejs20.x arm64
  build_wrapper 20 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs20x.x86_64.zip nodejs20.x x86_64
	;;
"build-publish-22-ecr-image")
  build_wrapper 22 arm64 
	publish_docker_ecr $DIST_DIR/nodejs22x.arm64.zip nodejs22.x arm64
  build_wrapper 22 x86_64 
	publish_docker_ecr $DIST_DIR/nodejs22x.x86_64.zip nodejs22.x x86_64
	;;
"nodejs16")
  $0 build-16
  $0 publish-16
  ;;
"nodejs18")
  $0 build-18
  $0 publish-18
  ;;  
"nodejs20")
  $0 build-20
  $0 publish-20
  ;;
"nodejs22")
  $0 build-22
  $0 publish-22
  ;;
*)
	usage
	;;
esac
