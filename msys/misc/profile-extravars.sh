#!/bin/sh

if test -n "$MOZILLABUILD"; then
    MSYS_MOZBUILD=$(cd "$MOZILLABUILD" && pwd)
    PATH="/local/bin:$MSYS_MOZBUILD/bin:$MSYS_MOZBUILD/info-zip:$MSYS_MOZBUILD/kdiff3:$MSYS_MOZBUILD/node-v8.11.1-win-x64:$MSYS_MOZBUILD/nsis-3.01:$MSYS_MOZBUILD/python:$MSYS_MOZBUILD/python/Scripts:$MSYS_MOZBUILD/python3:$MSYS_MOZBUILD/python3/Scripts:$MSYS_MOZBUILD/upx394w:$MSYS_MOZBUILD/watchman:$MSYS_MOZBUILD/wget:$PATH"
    EDITOR="emacs.exe"
    export PATH EDITOR
    export HOSTTYPE MACHTYPE OSTYPE SHELL
fi
