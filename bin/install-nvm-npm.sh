#!/bin/bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
#- name: Install nvm
#  ansible.builtin.shell: >
#    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
#  args:
#    creates: "{{ ansible_env.HOME }}/.nvm/nvm.sh"
nvm install v18.16.0
npm install -g @ansible/ansible-language-server
