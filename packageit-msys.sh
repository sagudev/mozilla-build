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

# The make 3.81 shipping with msys is still broken, so continue shipping this.
rm -rf "${MSYS_STAGEDIR}/make-3.81.90"
tar -xjf "${MSYS_SRCDIR}/make-3.81.90.tar.bz2" -C "${MSYS_STAGEDIR}"
pushd "${MSYS_STAGEDIR}/make-3.81.90"
patch -p0 < "${MSYS_SRCDIR}/make-msys.patch"
./configure --prefix=/local
make
make install prefix="${MSYS_STAGEDIR}/mozilla-build/msys/local"
popd

# Install some newer MSYS packages
#tar -jvxf "${MSYS_SRCDIR}/autoconf-2.61-MSYS-1.0.11.tar.bz2" -C "${MSYS_STAGEDIR}/mozilla-build/msys"
# Replace the native MSYS rm with winrm and move the tarballs that extract to usr/ up a level.
cp "${MSYS_SRCDIR}/winrm.exe" "${MSYS_STAGEDIR}/mozilla-build/msys/bin"
pushd "${MSYS_STAGEDIR}/mozilla-build/msys"
mv bin/rm.exe bin/rm-msys.exe
cp bin/winrm.exe bin/rm.exe
cp -R usr/* ./
rm -rf usr/
popd

chmod 755 "${MSYS_STAGEDIR}/mozilla-build/msys/bin/mktemp.exe"

# In order for this to actually work, we now need to rebase
# the DLL. Since I can't figure out how to rebase just one
# DLL to avoid conflicts with a set of others, we just
# rebase them all!
# Some DLLs won't rebase unless they are chmod 755
find "${MSYS_STAGEDIR}/mozilla-build/msys" -name "*.dll" | \
  xargs chmod 755

# Skip libW11.dll, since it doesn't rebase properly
find "${MSYS_STAGEDIR}/mozilla-build/msys" -name "*.dll" | \
  grep -v "libW11.dll" | \
  xargs editbin /REBASE:BASE=0x60000000,DOWN /DYNAMICBASE:NO
# Now rebase msys-1.0.dll to a special place because it's finicky
editbin /REBASE:BASE=0x60100000 /DYNAMICBASE:NO "${MSYS_STAGEDIR}/mozilla-build/msys/bin/msys-1.0.dll"
