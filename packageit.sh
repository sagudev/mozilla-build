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
cp "${MSYS_SRCDIR}/msys/misc/"{inputrc,minttyrc} "${MSYS_STAGEDIR}/mozilla-build/msys/etc"
cp "${MSYS_SRCDIR}/msys/misc/ssh_config" "${MSYS_STAGEDIR}/mozilla-build/msys/etc/ssh"
mkdir "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"
cp "${MSYS_SRCDIR}/msys/misc/"{profile-inputrc.sh,profile-extravars.sh,profile-echo.sh,profile-homedir.sh,profile-sshagent.sh} \
    "${MSYS_STAGEDIR}/mozilla-build/msys/etc/profile.d"

#
# Install other non-MSYS packages
#

# Copy mozmake
mkdir -p "${MSYS_STAGEDIR}/mozilla-build/mozmake"
cp "${MSYS_SRCDIR}/mozmake.exe" "${MSYS_STAGEDIR}/mozilla-build/mozmake/mozmake.exe"

# Install emacs
tar --lzma -vxf "${MSYS_SRCDIR}/emacs-25.2-bin-i686-mingw32.tar.lzma" -C "${MSYS_STAGEDIR}/mozilla-build/msys"

# Install info-zip
mkdir "${MSYS_STAGEDIR}/mozilla-build/info-zip"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" "${MSYS_SRCDIR}/unz600xN.exe"
unzip -d "${MSYS_STAGEDIR}/mozilla-build/info-zip" -o "${MSYS_SRCDIR}/zip300xN.zip"

# Install moztools-static
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/moztools-static.zip"

# Install UPX
unzip -d "${MSYS_STAGEDIR}/mozilla-build" "${MSYS_SRCDIR}/upx393w.zip"

# Install watchman
unzip -d "${MSYS_STAGEDIR}/mozilla-build/watchman" "${MSYS_SRCDIR}/watchman-d1d427f3.zip"

# Install wget
# Downloaded from https://eternallybored.org/misc/wget/
unzip -d "${MSYS_STAGEDIR}/mozilla-build/wget" "${MSYS_SRCDIR}/wget-1.19.1-win32.zip"
rm "${MSYS_STAGEDIR}/mozilla-build/wget/wget.exe.debug"

# Install yasm
mkdir "${MSYS_STAGEDIR}/mozilla-build/yasm"
cp "${MSYS_SRCDIR}/yasm-1.3.0-win32.exe" "${MSYS_STAGEDIR}/mozilla-build/yasm/yasm.exe"

# Install NSIS 3.0b1
# [http://sourceforge.net/projects/nsis/files/NSIS%203%20Pre-release/3.0b1/nsis-3.0b1.zip/download NSIS]
unzip -d "${MSYS_STAGEDIR}/mozilla-build" -o "${MSYS_SRCDIR}/nsis-3.0b1.zip"

# Rename the NSIS 3.0b1 command line executables
pushd "${MSYS_STAGEDIR}/mozilla-build/nsis-3.0b1"
mv makensis.exe makensis-3.0b1.exe
mv Bin/makensis.exe Bin/makensis-3.0b1.exe
popd

# Install NSIS 3.0b3
# [http://sourceforge.net/projects/nsis/files/NSIS%203%20Pre-release/3.0b3/nsis-3.0b3.zip/download NSIS]
unzip -d "${MSYS_STAGEDIR}/mozilla-build" -o "${MSYS_SRCDIR}/nsis-3.0b3.zip"

# Rename the NSIS 3.0b3 command line executables
pushd "${MSYS_STAGEDIR}/mozilla-build/nsis-3.0b3"
mv makensis.exe makensis-3.0b3.exe
mv Bin/makensis.exe Bin/makensis-3.0b3.exe
popd

# Update the copy of SQLite bundled with Python to version 3.17.0
unzip -d "${MSYS_STAGEDIR}/mozilla-build/python/DLLs" -o "${MSYS_SRCDIR}/sqlite-dll-win32-x86-3170000.zip"
rm "${MSYS_STAGEDIR}/mozilla-build/python/DLLs/sqlite3.def"

#
# Copy other miscellaneous files and stage for installer packaging
#

# Copy mercurial.ini to the python dir so Mercurial has sane defaults
cp "${MSYS_SRCDIR}"/mercurial.ini "${MSYS_STAGEDIR}/mozilla-build/python"

# Copy over CA certificates in PEM format (converted from Firefox's defaults) so SSL will work
# This is used by both Mercurial and wget
cp "${MSYS_SRCDIR}"/ca-bundle.crt "${MSYS_STAGEDIR}/mozilla-build/msys/etc"

# Copy the batch files that make everything go!
cp "${MSYS_SRCDIR}"/{start-shell.bat,start-shell-msvc2015.bat,start-shell-msvc2015-x64.bat} "${MSYS_STAGEDIR}/mozilla-build"

# Copy VERSION file
cp "${MSYS_SRCDIR}"/VERSION "${MSYS_STAGEDIR}/mozilla-build"

# Stage files to make the installer
cp "${MSYS_SRCDIR}"/{license.rtf,installit.nsi} "${MSYS_STAGEDIR}"
version=`cat "${MSYS_SRCDIR}"/VERSION`
sed < "${MSYS_SRCDIR}"/version.nsi s/@VERSION@/$version/g > "${MSYS_STAGEDIR}"/version.nsi
unix2dos "${MSYS_STAGEDIR}/license.rtf"
