#!/bin/sh

if test -n "$MOZILLABUILD"; then
    MSYS_MOZBUILD=$(cd "$MOZILLABUILD" && pwd)
    PATH="/local/bin:$MSYS_MOZBUILD/wget:$MSYS_MOZBUILD/7zip:$MSYS_MOZBUILD/blat261/full:$MSYS_MOZBUILD/python25:$MSYS_MOZBUILD/svn-win32-1.6.3/bin:$MSYS_MOZBUILD/upx203w:$MSYS_MOZBUILD/emacs-22.3/bin:$MSYS_MOZBUILD/info-zip:$MSYS_MOZBUILD/nsis-2.33u:$MSYS_MOZBUILD/nsis-2.46u:$MSYS_MOZBUILD/hg:$MSYS_MOZBUILD/python25/Scripts:$MSYS_MOZBUILD/kdiff3:$PATH:$MSYS_MOZBUILD/vim/vim72"
    EDITOR="emacs.exe --no-window-system"
    CVS_RSH=ssh
    APR_ICONV_PATH="$MSYS_MOZBUILD/svn-win32-1.6.3/iconv"
    export PATH EDITOR CVS_RSH APR_ICONV_PATH
    export HOSTTYPE MACHTYPE OSTYPE SHELL
fi