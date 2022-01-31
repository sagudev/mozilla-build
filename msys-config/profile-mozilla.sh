#!/bin/sh

export EDITOR="nano.exe"
export GIT_EDITOR="nano -b -r 72"
export HGEDITOR="nano -b -r 72"
export HGENCODING=utf-8
if test -n "$MOZILLABUILD"; then
  # $MOZILLABUILD should always be set by start-shell.bat.
  echo "MozillaBuild Install Directory: ${MOZILLABUILD}"
  mozillabuild_unix=$(cygpath -u "$MOZILLABUILD")
  mozillabuild_unix=${mozillabuild_unix%/} # Remove trailing slash
  PATH="$mozillabuild_unix/bin:$mozillabuild_unix/kdiff3:$mozillabuild_unix/python3:$mozillabuild_unix/python3/Scripts:$PATH"

  # Pip-installed mercurial puts two files in the Python Scripts directory: "hg" (a text, unix-y file), and "hg.exe".
  # Use hg.exe to avoid https://bz.mercurial-scm.org/show_bug.cgi?id=6614
  alias hg=hg.exe
fi

if [ -z "$EXTERNAL_TO_MOZILLABUILD_SSH_DIR" ]; then
  # This script loads ssh-agent and shares the instance across multiple instances
  # of rxvt.
  #
  # Written and released under GPL by Joseph Reagle, found here:
  # http://www.cygwin.com/ml/cygwin/2001-06/msg00537.html
  #
  # This program is free software: you can redistribute it and/or modify
  # it under the terms of the GNU General Public License as published by
  # the Free Software Foundation, either version 3 of the License, or
  # (at your option) any later version.
  #
  # This program is distributed in the hope that it will be useful,
  # but WITHOUT ANY WARRANTY; without even the implied warranty of
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  # GNU General Public License for more details.
  #
  # You should have received a copy of the GNU General Public License
  # along with this program.  If not, see <http://www.gnu.org/licenses/>.
  SSH_ENV="$HOME/.ssh/environment"

  function start_agent {
    ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    ssh-add;
  }

  if [ -d "$HOME/.ssh" ]; then
    if [ -f "${SSH_ENV}" ]; then
      . "${SSH_ENV}" > /dev/null
      ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
      }
    else
      start_agent;
    fi
  fi
else
  PATH="$(cygpath -u $EXTERNAL_TO_MOZILLABUILD_SSH_DIR):$PATH"
fi
