# Build mozmake from a source archive cloned from the upstream canonical location of
# git://git.savannah.gnu.org/make.git/.
#
# The archive was created by running the following command and then running bzip2 on it:
#   git archive -o make-`git describe HEAD`.tar --format=tar --prefix=make-`git describe HEAD`/ HEAD
#
# This script is intended to be run within a MozillaBuild shell started from an appropriate start-shell*.bat
# script so that the appropriate paths are already configured. Run it side-by-side with the source archive
# and the end result will be a new mozmake.exe in the same directory.

MAKE_VERSION="4.2.1-108-g8c888d9"
mkdir -p mozmake
tar -xjf "make-${MAKE_VERSION}.tar.bz2" -C mozmake
pushd "mozmake/make-${MAKE_VERSION}"
sed "s/%PACKAGE%/make/;s/%VERSION%/${MAKE_VERSION}/;/#define BATCH_MODE_ONLY_SHELL/s/\/\*\(.*\)\*\//\1/" src/config.h.W32.template > src/config.h.W32
cmd /c bootstrap.bat
cmd /c build_w32.bat
cp WinRel/gnumake.exe "../../mozmake.exe"
popd
rm -rf mozmake
