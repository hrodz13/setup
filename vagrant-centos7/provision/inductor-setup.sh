#!/bin/sh

export INDUCTOR_HOME="/opt/oneops/inductor"
export BUILD_HOME="/home/oneops/build/repos"

sudo -s -u ooadmin

sudo rm -R "$INDUCTOR_HOME/shared"
sudo rm "$INDUCTOR_HOME/circuit-oneops-1"

sudo ln -s "$BUILD_HOME/circuit-oneops-1" "$INDUCTOR_HOME/circuit-oneops-1"
sudo ln -s "$BUILD_HOME/oneops-admin/lib/shared" "$INDUCTOR_HOME/shared"

cd "$INDUCTOR_HOME/circuit-oneops-1"; circuit install


