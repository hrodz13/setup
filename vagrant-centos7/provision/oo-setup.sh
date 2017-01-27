#!/bin/sh

mkdir -p /home/oneops
cd /home/oneops

export BUILD_BASE='/home/oneops/build'
export OO_HOME='/home/oneops'
export GITHUB_URL='https://github.com/oneops'

mkdir -p $BUILD_BASE

if [ -d "$BUILD_BASE/dev-tools" ]; then
  echo "doing git pull on dev-tools"
  cd "$BUILD_BASE/dev-tools"
  git pull
else
  echo "doing dev tools git clone"
  cd $BUILD_BASE
  git clone "$GITHUB_URL/dev-tools.git"
fi
sleep 2

cd $OO_HOME

cp $BUILD_BASE/dev-tools/setup-scripts/* .

export PATH=$PATH:/usr/local/bin

./oneops_build.sh "$@"

if [ $? -ne 0 ]; then
  exit 1;
fi

if [ -z $OO_VALIDATION ]; then
	echo "OO_VALIDATION environment variable has not neen set in the host machine.. Skipping OneOps Validation"
elif [ $OO_VALIDATION == "false" ]; then
	echo "OO_VALIDATION environment variable is set as false in the host machine.. Skipping OneOps Validation"
elif [ $OO_VALIDATION == "true" ]; then
	echo "OO_VALIDATION environment variable is set as true in the host machine.. Doing OneOps Validation"
	./oo_test.rb
fi

now=$(date +"%T")
echo "All done at : $now"
