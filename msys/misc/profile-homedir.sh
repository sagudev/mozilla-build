#!/bin/sh

if test -n "$USERPROFILE" -a "$HOME" = "/home/$LOGNAME"; then
    HOME=$(cd "$USERPROFILE" && pwd)
fi
export HOME
