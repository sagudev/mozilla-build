#!/bin/sh

if test -n "$MOZILLABUILD"; then
    MSYS_MOZBUILD=$(cd "$MOZILLABUILD" && pwd)
    PATH="/local/bin:$MSYS_MOZBUILD/wget:$MSYS_MOZBUILD/7zip:$MSYS_MOZBUILD/python:$MSYS_MOZBUILD/python/Scripts:$MSYS_MOZBUILD/upx391w:$MSYS_MOZBUILD/emacs-24.3/bin:$MSYS_MOZBUILD/info-zip:$MSYS_MOZBUILD/nsis-2.46u:$MSYS_MOZBUILD/nsis-3.0a2:$MSYS_MOZBUILD/kdiff3:$MSYS_MOZBUILD/yasm:$MSYS_MOZBUILD/mozmake:$PATH"
    EDITOR="emacs.exe"
    export PATH EDITOR
    export HOSTTYPE MACHTYPE OSTYPE SHELL
fi
