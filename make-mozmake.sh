# Build mozmake from a source archive cloned from the upstream canonical location of
# git://git.savannah.gnu.org/cgit/make.git/.
#
# The archive was created by running the following command and then running bzip2 on it:
#   git archive -o make-`git describe HEAD`.tar --format=tar --prefix=make-`git describe HEAD`/ HEAD
#
# This script is intended to be run within a MozillaBuild shell started from an appropriate start-shell*.bat
# script so that the appropriate paths are already configured. Run it side-by-side with the source archive
# and the end result will be a new mozmake.exe in the same directory.

MAKE_VERSION="4.2.1-30-ga95cb30"
mkdir -p mozmake
tar -xjf "make-${MAKE_VERSION}.tar.bz2" -C mozmake
pushd "mozmake/make-${MAKE_VERSION}"
sed "s/%PACKAGE%/make/;s/%VERSION%/${MAKE_VERSION}/;/#define BATCH_MODE_ONLY_SHELL/s/\/\*\(.*\)\*\//\1/" config.h.W32.template > config.h.W32
# Work around an upstream subproc build issue
sed "/^CFLAGS_any/ s/$/ -I..\/..\/glob/" w32/subproc/NMakefile > w32/subproc/NMakefile2 && mv w32/subproc/NMakefile2 w32/subproc/NMakefile
cp NMakefile.template NMakefile
nmake -f NMakefile
cp WinRel/make.exe "../../mozmake.exe"
popd
rm -rf mozmake
