set -e

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

#
# Extract and configure the MSYS environment
#

# Extract MSYS packages to the stage directory
mkdir -p "${MSYS_STAGEDIR}/mozilla-build/msys"
find "${MSYS_SRCDIR}/msys" -name "*.lzma" | xargs -I file tar --lzma -vxf file -C "${MSYS_STAGEDIR}/mozilla-build/msys"

# Replace the native MSYS rm with winrm.
cp "${MSYS_SRCDIR}/winrm.exe" "${MSYS_STAGEDIR}/mozilla-build/msys/bin"
pushd "${MSYS_STAGEDIR}/mozilla-build/msys"
mv bin/rm.exe bin/rm-msys.exe
cp bin/winrm.exe bin/rm.exe
popd

# mktemp.exe extracts as read-only, which breaks manifest embedding
chmod 755 "${MSYS_STAGEDIR}/mozilla-build/msys/bin/mktemp.exe"

# Copy the vi shell script to the bin dir
cp "${MSYS_SRCDIR}/msys/misc/vi" "${MSYS_STAGEDIR}/mozilla-build/msys/bin"

# Build and install autoconf 2.13
tar -xzf "${MSYS_SRCDIR}/autoconf-2.13.tar.gz" -C "${MSYS_STAGEDIR}"
pushd "${MSYS_STAGEDIR}/autoconf-2.13"
./configure --prefix=/local --program-suffix=-2.13
make
make install prefix="${MSYS_STAGEDIR}/mozilla-build/msys/local"
popd

# The make 3.81 shipping with msys is still broken, so build and install version 3.81.90 instead.
rm -rf "${MSYS_STAGEDIR}/make-3.81.90"
tar -xjf "${MSYS_SRCDIR}/make-3.81.90.tar.bz2" -C "${MSYS_STAGEDIR}"
pushd "${MSYS_STAGEDIR}/make-3.81.90"
patch -p0 < "${MSYS_SRCDIR}/make-msys.patch"
MSYSTEM=MSYS ./configure --prefix=/local
make
make install prefix="${MSYS_STAGEDIR}/mozilla-build/msys/local"
popd

# In order for this to actually work, we now need to rebase
# the DLL. Since I can't figure out how to rebase just one
# DLL to avoid conflicts with a set of others, we just
# rebase them all!
# Some DLLs won't rebase unless they are chmod 755
find "${MSYS_STAGEDIR}/mozilla-build/msys" -name "*.dll" | \
  xargs chmod 755

# Skip msys-W11.dll, since it doesn't rebase properly
find "${MSYS_STAGEDIR}/mozilla-build/msys" -name "*.dll" | \
  grep -v "msys-W11.dll" | \
  xargs editbin /REBASE:BASE=0x60000000,DOWN /DYNAMICBASE:NO
# Now rebase msys-1.0.dll to a special place because it's finicky
editbin /REBASE:BASE=0x60100000 /DYNAMICBASE:NO "${MSYS_STAGEDIR}/mozilla-build/msys/bin/msys-1.0.dll"

# Copy various configuration files
cp "${MSYS_SRCDIR}/msys/misc/inputrc" "${MSYS_STAGEDIR}/mozilla-build/msys/etc"
mkdir "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"
cp "${MSYS_SRCDIR}/msys/misc/"{profile-inputrc.sh,profile-extravars.sh,profile-echo.sh,profile-homedir.sh,profile-sshagent.sh} \
    "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"

#
# Install other non-MSYS packages
#

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

# Install emacs
tar --lzma -vxf "${MSYS_SRCDIR}/emacs-24.4-bin.tar.lzma" -C "${MSYS_STAGEDIR}/mozilla-build/msys"

# Install info-zip
mkdir "${MSYS_STAGEDIR}/mozilla-build/info-zip"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" "${MSYS_SRCDIR}/unz600xN.exe"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" -o "${MSYS_SRCDIR}/zip300xN.zip"

# Install moztools-static
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/moztools-static.zip"

# Install UPX
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/upx391w.zip"

# Install wget
unzip -d "${MSYS_STAGEDIR}/mozilla-build/wget" "${MSYS_SRCDIR}/wget-1.16.1b.zip"
rm "${MSYS_STAGEDIR}/mozilla-build/wget/wget.exe.debug"

# Install yasm
mkdir "${MSYS_STAGEDIR}/mozilla-build/yasm"
cp "${MSYS_SRCDIR}/yasm-1.3.0-win32.exe" "${MSYS_STAGEDIR}/mozilla-build/yasm/yasm.exe"

#
# Copy other miscellaneous files and stage for installer packaging
#

# Copy mercurial.ini to the python dir so Mercurial has sane defaults
cp "${MSYS_SRCDIR}"/mercurial.ini "${MSYS_STAGEDIR}/mozilla-build/python"

# Patch Mercurial 3.3.x to better support color when running in MSYS
# This patch will be included in Mercurial 3.4+
pushd "${MSYS_STAGEDIR}/mozilla-build/python/Lib/site-packages"
patch -p1 -i "${MSYS_SRCDIR}/hg33-color.patch"
popd
# Run a basic hg command to regenerate the .pyc files
PATH="${MSYS_STAGEDIR}/mozilla-build/python:${MSYS_STAGEDIR}/mozilla-build/python/Scripts:$PATH"
hg identify https://hg.mozilla.org/mozilla-central

# Copy over CA certificates in PEM format (converted from Firefox's defaults) so SSL will work
# This is used by both Mercurial and wget
cp "${MSYS_SRCDIR}"/ca-bundle.crt "${MSYS_STAGEDIR}/mozilla-build/msys/etc"

# Copy the batch files that make everything go!
cp "${MSYS_SRCDIR}"/{start-shell.bat,start-shell-msvc2013.bat,start-shell-msvc2013-x64.bat,start-shell-msvc2015.bat,start-shell-msvc2015-x64.bat} "${MSYS_STAGEDIR}/mozilla-build"

# Copy VERSION file
cp "${MSYS_SRCDIR}"/VERSION "${MSYS_STAGEDIR}/mozilla-build"

# Stage files to make the installer
cp "${MSYS_SRCDIR}"/{license.rtf,installit.nsi} "${MSYS_STAGEDIR}"
version=`cat "${MSYS_SRCDIR}"/VERSION`
sed < "${MSYS_SRCDIR}"/version.nsi s/@VERSION@/$version/g > "${MSYS_STAGEDIR}"/version.nsi
unix2dos "${MSYS_STAGEDIR}/license.rtf"
