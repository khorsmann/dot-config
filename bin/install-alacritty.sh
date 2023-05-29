#!/bin/bash

sudo apt-get update -y
sudo apt install cmake pkg-config libfreetype6-dev \
  libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev \
  python3 curl gcc make build-essential scdoc gzip

echo "setup rust/cargo"
curl https://sh.rustup.rs -sSf | sh

echo "cargo install alacritty"
cargo install alacritty

if [ -d $HOME/.cargo/bin/ ]; then
  if [ -f $HOME/.cargo/bin/alacritty ]; then
    sudo chmod +x $HOME/.cargo/bin/alacritty
    sudo cp -avx $HOME/.cargo/bin/alacritty /usr/local/bin
  else
    echo "error no alacritty in cargo bin"
    exit 1
  fi
fi

if [ -d $HOME/_git ]; then
  pushd $HOME/_git 
  if [ ! -d alacritty ]; then
    echo "git clone for desktop stuff"
    git clone https://github.com/alacritty/alacritty.git
  fi
  cd alacritty
  sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
  sudo desktop-file-install extra/linux/Alacritty.desktop
  sudo update-desktop-database
  sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
  sudo mkdir -p /usr/local/share/man/man1
  scdoc < extra/man/alacritty.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
  scdoc < extra/man/alacritty-msg.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null
fi
