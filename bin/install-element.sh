sudo wget -O /usr/share/keyrings/riot-im-archive-keyring.gpg https://packages.riot.im/debian/riot-im-archive-keyring.gpg

wget -qO- https://packages.riot.im/debian/riot-im-archive-keyring.gpg | gpg --dearmor > riot-im-archive-keyring.gpg
sudo install -o root -g root -m 644 riot-im-archive-keyring.gpg /etc/apt/trusted.gpg.d/

sudo sh -c 'echo "deb [signed-by=/etc/apt/trusted.gpg.d/riot-im-archive-keyring.gpg] https://packages.riot.im/debian/ default main" > /etc/apt/sources.list.d/riot.list'
rm -f riot-im-archive-keyring.gpg

sudo apt install apt-transport-https
sudo apt-get update
sudo apt-get install element-desktop
