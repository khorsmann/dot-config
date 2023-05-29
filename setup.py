#!/usr/bin/env python3
import re
import os
import os.path
import sys
from collections import defaultdict
import pprint

"""
BLACKLIST = filenames and/or absolute path to folder to ignore them
"""

HOME = os.environ['HOME']
MYPATH = os.path.normpath(os.path.dirname(os.path.realpath(__file__)))
MYNAME = os.path.normpath(os.path.basename(os.path.realpath(__file__)))
GITFOLDER = [ x[0] for x in os.walk(os.path.join(MYPATH, '.git'))]
BLACKLIST = set([ MYNAME,
                '.gitignore',
                'README.md',
                'install.pl',
                ] + GITFOLDER )


def defaultdict_factory(*args, **kwargs):
    """ Create and return a defaultdict(dict).  """
    return defaultdict(dict, *args, **kwargs)


def prefix_rewrite(src):
    dest = re.sub(r'^dot-', '.', src)
    if sys.platform.startswith('openbsd'):
        if src.startswith('dot-linux'):
            return False
    dest = re.sub(r'^.openbsd-', '.', dest)
    if sys.platform.startswith('linux'):
        if src.startswith('dot-openbsd'):
            return False
    dest = re.sub(r'^.linux-', '.', dest)
    return dest


def addfiles(filedict, root, tfolder, files):
    """ add Files to Source/Target Dict for ln -s """
    for s in files:
        if s in BLACKLIST:
            continue
        if root in BLACKLIST:
            continue
        t = prefix_rewrite(s)
        if not t:
            continue
        s = os.path.join(root, s)
        filedict['FILES'][s] = os.path.join(tfolder, t)
    return filedict


def main():

    filedict = defaultdict(defaultdict_factory)

    for root, _, files in os.walk(MYPATH):
        if files:
            tfolder = (''.join([HOME, root[len(MYPATH):]]))
            if tfolder != HOME:
                if root not in BLACKLIST:
                    filedict['FOLDERS'][tfolder] = oct(os.stat(root).st_mode & 0o777)
            filedict = addfiles(filedict, root, tfolder, files)

    DEBUG = os.environ.get('DEBUG')
    if isinstance(DEBUG, str):
        if DEBUG.lower() == 'true':
            pprint.pprint(filedict)
            sys.exit(1)

    # generate folders
    for folder, oct_rights in sorted(filedict['FOLDERS'].items()):
        if not os.path.isdir(folder):
            print('mkdir -p {0}'.format(folder))
            os.makedirs(folder)
            print('chmod {0} {1}'.format(oct_rights[2:], folder))
            os.chmod(folder,int(oct_rights,8))

    # generate symlinks
    for src, dest in sorted(filedict['FILES'].items()):
        if os.path.isfile(dest) and not os.path.islink(dest):
            bak = '.'.join([dest, 'bak'])
            print('mv {0} {1}'.format(dest, bak))
            os.rename(dest, bak)
        if not os.path.islink(dest):
            print('ln -s {0} {1}'.format(src, dest))
            os.symlink(src, dest)


if __name__ == '__main__':
    main()
