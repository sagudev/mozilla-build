#!/bin/sh

if test -n "$MOZILLABUILD"; then
    MSYS_MOZBUILD=$(cd "$MOZILLABUILD" && pwd)
    PATH="/local/bin:$MSYS_MOZBUILD/wget:$MSYS_MOZBUILD/7zip:$MSYS_MOZBUILD/python:$MSYS_MOZBUILD/svn-win32-1.6.3/bin:$MSYS_MOZBUILD/upx391w:$MSYS_MOZBUILD/emacs-24.3/bin:$MSYS_MOZBUILD/info-zip:$MSYS_MOZBUILD/nsis-2.46u:$MSYS_MOZBUILD/nsis-3.0a2:$MSYS_MOZBUILD/wix-351728:$MSYS_MOZBUILD/hg:$MSYS_MOZBUILD/python/Scripts:$MSYS_MOZBUILD/kdiff3:$MSYS_MOZBUILD/yasm:$MSYS_MOZBUILD/mozmake:$PATH:$MSYS_MOZBUILD/vim/vim72"
    EDITOR="emacs.exe"
    CVS_RSH=ssh
    APR_ICONV_PATH="$MSYS_MOZBUILD/svn-win32-1.6.3/iconv"
    WIX_351728_PATH="$MSYS_MOZBUILD/wix-351728"
    export PATH EDITOR CVS_RSH APR_ICONV_PATH WIX_351728_PATH
    export HOSTTYPE MACHTYPE OSTYPE SHELL
fi
