#!/bin/sh

if test -n "$MOZILLABUILD"; then
    MSYS_MOZBUILD=$(cd "$MOZILLABUILD" && pwd)
    PATH="/local/bin:$MSYS_MOZBUILD/bin:$MSYS_MOZBUILD/kdiff3:$MSYS_MOZBUILD/nsis-3.01:$MSYS_MOZBUILD/python:$MSYS_MOZBUILD/python/Scripts:$MSYS_MOZBUILD/python3:$MSYS_MOZBUILD/python3/Scripts:$PATH"
    EDITOR="emacs.exe"
    export PATH EDITOR
    export HOSTTYPE MACHTYPE OSTYPE SHELL
fi
