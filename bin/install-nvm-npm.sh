#!/bin/bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
#- name: Install nvm
#  ansible.builtin.shell: >
#    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
#  args:
#    creates: "{{ ansible_env.HOME }}/.nvm/nvm.sh"
nvm install v18.16.1
npm install -g bash-language-server
npm install -g @ansible/ansible-language-server
npm install -g yaml-language-server@next
