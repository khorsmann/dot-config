#!/usr/env bash
echo "build environment for pyenv"
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
echo "add pyenv-update"
git clone https://github.com/pyenv/pyenv-update.git $(pyenv root)/plugins/pyenv-update

