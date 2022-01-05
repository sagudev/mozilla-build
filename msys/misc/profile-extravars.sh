#!/bin/sh

export EDITOR="emacs.exe"
if test -n "$MOZILLABUILD"; then
    PATH="$MOZILLABUILD/bin:$MOZILLABUILD/kdiff3:$MOZILLABUILD/python3:$MOZILLABUILD/python3/Scripts:$MOZILLABUILD/python:$MOZILLABUILD/python/Scripts:$PATH"
fi
