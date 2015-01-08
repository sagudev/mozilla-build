set -e
set -v

# This script expects these to be absolute paths in win32 format
if test -z "$MOZ_SRCDIR"; then
    echo "This script should be run from packageit.py (MOZ_SRCDIR missing)."
    exit 1
fi
if test -z "$MOZ_STAGEDIR"; then
    echo "This script should be run from packageit.py (MOZ_STAGEDIR missing)."
    exit 1
fi

MSYS_SRCDIR=$(cd "$MOZ_SRCDIR" && pwd)
MSYS_STAGEDIR=$(cd "$MOZ_STAGEDIR" && pwd)

# Patch Mercurial.ini
pushd "${MSYS_STAGEDIR}/mozilla-build/hg/hgrc.d"
patch -p0 < "${MSYS_SRCDIR}/Mercurial.rc.patch"
popd

# install emacs
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/emacs-24.3-bin-i386.zip"

# install vim
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/vim72rt.zip"
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/vim72w32.zip"
unzip -o -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/gvim72.zip"
# copy the vi and view shell scripts to the bin dir
cp "${MSYS_SRCDIR}"/{vi,view} "${MSYS_STAGEDIR}"/mozilla-build/vim/vim72

# install UPX
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/upx391w.zip"

# install SVN
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/svn-win32-1.6.3.zip"

# install unzip
mkdir "${MSYS_STAGEDIR}/mozilla-build/info-zip"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" "${MSYS_SRCDIR}/unz600xN.exe"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" -o "${MSYS_SRCDIR}/zip300xN.zip"

# build and install libiconv
rm -rf "${MSYS_STAGEDIR}/libiconv-1.11"
tar -xzf "${MSYS_SRCDIR}/libiconv-1.11.tar.gz" -C "${MSYS_STAGEDIR}"

pushd "${MSYS_STAGEDIR}/libiconv-1.11"
patch -p0 < "${MSYS_SRCDIR}/libiconv-build.patch"
./configure --prefix=/local --enable-static --disable-shared
make
make install DESTDIR="${MSYS_STAGEDIR}/mozilla-build/msys" LIBTOOL_INSTALL=
popd

# install moztools-static
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/moztools-static.zip"

# Copy various configuration files
cp "${MSYS_SRCDIR}/inputrc" "${MSYS_STAGEDIR}/mozilla-build/msys/etc"
mkdir "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"
cp "${MSYS_SRCDIR}"/{profile-inputrc.sh,profile-extravars.sh,profile-echo.sh,profile-homedir.sh,profile-sshagent.sh} \
    "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"

# Copy the batch files that make everything go!
cp "${MSYS_SRCDIR}"/{guess-msvc.bat,start-shell-l10n.bat,start-shell-msvc2010.bat,start-shell-msvc2010-x64.bat,start-shell-msvc2012.bat,start-shell-msvc2012-x64.bat,start-shell-msvc2013.bat,start-shell-msvc2013-x64.bat,start-shell-msvc2015.bat,start-shell-msvc2015-x64.bat} "${MSYS_STAGEDIR}/mozilla-build"

# Copy VERSION file
cp "${MSYS_SRCDIR}"/VERSION "${MSYS_STAGEDIR}/mozilla-build"

# Install autoconf 2.13
tar -xzf "${MSYS_SRCDIR}/autoconf-2.13.tar.gz" -C "${MSYS_STAGEDIR}"
pushd "${MSYS_STAGEDIR}/autoconf-2.13"
./configure --prefix=/local --program-suffix=-2.13
make
make install prefix="${MSYS_STAGEDIR}/mozilla-build/msys/local"
popd

# Install wget
unzip -d "${MSYS_STAGEDIR}/mozilla-build/wget" "${MSYS_SRCDIR}/wget-1.15b.zip"
# copy over CA certificates in PEM format (converted from Firefox's defaults)
# so SSL will work
cp "${MSYS_SRCDIR}"/ca-bundle.crt "${MSYS_STAGEDIR}/mozilla-build/wget"

# Install yasm
mkdir "${MSYS_STAGEDIR}/mozilla-build/yasm"
cp "${MSYS_SRCDIR}/yasm-1.3.0-win32.exe" "${MSYS_STAGEDIR}/mozilla-build/yasm/yasm.exe"

# stage files to make the installer
cp "${MSYS_SRCDIR}"/{license.rtf,installit.nsi} "${MSYS_STAGEDIR}"
version=`cat "${MSYS_SRCDIR}"/VERSION`
sed < "${MSYS_SRCDIR}"/version.nsi s/@VERSION@/$version/g > "${MSYS_STAGEDIR}"/version.nsi
unix2dos "${MSYS_STAGEDIR}/license.rtf"

# Build and install mozmake
MAKE_VERSION="4.1"
tar -xjf "${MSYS_SRCDIR}/mozmake/make-${MAKE_VERSION}.tar.bz2" -C "${MSYS_STAGEDIR}"
pushd "${MSYS_STAGEDIR}/make-${MAKE_VERSION}"
sed "s/%PACKAGE%/make/;s/%VERSION%/${MAKE_VERSION}/;/#define BATCH_MODE_ONLY_SHELL/s/\/\*\(.*\)\*\//\1/" config.h.W32.template > config.h.W32
cp NMakefile.template NMakefile
nmake -f NMakefile
mkdir "${MSYS_STAGEDIR}/mozilla-build/mozmake"
cp WinRel/make.exe "${MSYS_STAGEDIR}/mozilla-build/mozmake/mozmake.exe"
popd
