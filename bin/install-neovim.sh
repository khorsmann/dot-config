#!/bin/env bash
RELEASE="v0.9.5"
URL="https://github.com/neovim/neovim/releases/download"
FILE="/usr/local/bin/nvim_${RELEASE}.appimage"
if [ -f ${FILE} ] ; then
    echo "File already exist: $FILE"
    exit 1
fi
cd /usr/local/bin/
sudo wget -q ${URL}/${RELEASE}/nvim.appimage -O nvim_${RELEASE}.appimage
sudo chmod +x nvim_${RELEASE}.appimage
sudo ln -sf nvim_${RELEASE}.appimage nvim
