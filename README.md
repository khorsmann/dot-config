## Dot-Config Folder

Should be become my folder for $HOME/.dot-file templates<br/>
<br/>
Symlinks $dot-config/.dot-file to $HOME/.file<br/>

## Example run setup.py

The setup.py Script prints SHELL equivalent what happens right now.<br/>
If a file is already there, it becomes an .bak suffix and will renamed.<br/>

```shell
karsten@t60:~/src/dot-config$ ./setup.py 
mv /home/karsten/.bashrc /home/karsten/.bashrc.bak
ln -s /home/karsten/src/dot-config/dot-linux-bashrc /home/karsten/.bashrc
mv /home/karsten/.profile /home/karsten/.profile.bak
ln -s /home/karsten/src/dot-config/dot-linux-profile /home/karsten/.profile
mv /home/karsten/.screenrc /home/karsten/.screenrc.bak
ln -s /home/karsten/src/dot-config/dot-screenrc /home/karsten/.screenrc
ln -s /home/karsten/src/dot-config/dot-tmux.conf /home/karsten/.tmux.conf
```

