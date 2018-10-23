#!python.exe

# Create a MozillaBuild installer.
#
# This packaging script is intended to be entirely self-contained. However, it's within the realm
# of possibility of making changes to the host machine it's running on, so it's recommmended to
# be run within a VM instead.
#
# System Requirements:
#   * 64-bit Windows 7+
#   * Existing MozillaBuild installation
#   * Visual Studio 2017 or newer
#   * Windows 10 SDK (included with Visual Studio installer, just be sure it's installed!)
#
# Usage Instructions:
#   The script has built-in defaults that should allow for the package to be built simply by
#   invoking ./packageit.py from a MozillaBuild terminal. It also supports command line arguments
#   for changing the default paths if desired.
#

from os.path import join
from shutil import copyfile, copytree
from subprocess import check_call, check_output
import glob, optparse, os, os.path, zipfile
import _winreg as winreg

def get_vs_path():
    def vswhere(property):
        return check_output(["vswhere", "-format", "value", "-property", property]).decode('mbcs', 'replace')

    return vswhere("installationPath").rstrip()

def get_sdk_path():
    sdk_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0")
    sdk_dir = winreg.QueryValueEx(sdk_key, "InstallationFolder")[0]
    sdk_version = winreg.QueryValueEx(sdk_key, "ProductVersion")[0] + ".0"
    
    return join(sdk_dir, "bin", sdk_version, "x64")

# Set default values for the source and stage directories.
sourcedir = join(os.path.split(os.path.abspath(__file__))[0])
stagedir = "c:\\mozillabuild-stage"
vsdir = get_vs_path()
sdkdir = get_sdk_path()

# Override the source and/or stage directory locations if otherwise specified.
oparser = optparse.OptionParser()
oparser.add_option("-s", "--source", dest="sourcedir", help="Path to the MozillaBuild source.")
oparser.add_option("-o", "--output", dest="stagedir", help="Path to the desired staging directory.")
oparser.add_option("-v", "--visual-studio", dest="vsdir", help="Path to the Visual Studio installation.")
oparser.add_option("-w", "--winsdk", dest="sdkdir", help="Path to the Windows SDK installation.")
(options, args) = oparser.parse_args()

if len(args) != 0:
    raise Exception("Unexpected arguments passed to command line.")

if options.sourcedir:
    sourcedir = options.sourcedir
if options.stagedir:
    stagedir = options.stagedir
if options.vsdir:
    vsdir = options.vsdir
if options.sdkdir:
    sdkdir = options.sdkdir

pkgdir = join(stagedir, "mozilla-build")

# Read the version number
with open(join(sourcedir, "VERSION")) as f:
    version = f.read().splitlines()[0]

print "*****************************************"
print "Packaging MozillaBuild version: " + version
print "*****************************************"
print ""
print "Visual Studio location: " + vsdir
print "Windows SDK location: " + sdkdir
print "Source location: " + sourcedir
print "Output location: " + stagedir
print ""

# Remove the old stage directory if it's already present.
# We use cmd.exe instead of sh.rmtree because it's more forgiving of open handles than
# Python is (i.e. not hard-stopping if you happen to have the stage directory open in
# Windows Explorer while testing.
print "Removing the old stage directory..." + "\n"
if os.path.exists(stagedir):
    check_call(["cmd.exe", "/C", "rmdir /S /Q %s" % stagedir])

# Create the staging directories
if not os.path.exists(stagedir):
    os.mkdir(stagedir)
if not os.path.exists(pkgdir):
    os.mkdir(pkgdir)

# Create a bin directory as a place for miscellaneous tools to go.
if not os.path.exists(join(pkgdir, "bin")):
    os.mkdir(join(pkgdir, "bin"))

# Install 7-Zip. Create an administrative install point and copy the files to stage rather
# than using a silent install to avoid installing the shell extension on the host machine.
print "Staging 7-Zip..."
check_call(["msiexec.exe", "/q", "/a", join(sourcedir, "7z1805-x64.msi"),
            "TARGETDIR=" + join(stagedir, "7zip")])
copytree(join(stagedir, r"7zip\Files\7-Zip"), join(pkgdir, r"bin\7zip"))
# Copy 7z.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\7zip\7z.exe"), join(pkgdir, r"bin\7z.exe"))
copyfile(join(pkgdir, r"bin\7zip\7z.dll"), join(pkgdir, r"bin\7z.dll"))

# Install Python 2.7 in the stage directory. Create an administrative install point to avoid
# polluting the host machine along the way.
print "Staging Python 2.7 and extra packages..."
python27_dir = join(pkgdir, "python")
python_installer = "python-2.7.15.amd64.msi"
check_call(["msiexec.exe", "/q", "/a", join(sourcedir, python_installer),
            "TARGETDIR=" + python27_dir])
# Copy python.exe to python2.exe & python2.7.exe and remove the MSI.
copyfile(join(python27_dir, "python.exe"), join(python27_dir, "python2.exe"))
copyfile(join(python27_dir, "python.exe"), join(python27_dir, "python2.7.exe"))
os.remove(join(python27_dir, python_installer))

# Update the copy of SQLite bundled with Python to version 3.23.1.
sqlite_file = "sqlite-dll-win64-x64-3230100.zip"
with zipfile.ZipFile(join(sourcedir, sqlite_file), 'r') as sqlite3_zip:
    sqlite3_zip.extract("sqlite3.dll", join(python27_dir, "DLLs"))

# Run ensurepip and update to the latest version.
check_call([join(python27_dir, "python.exe"), "-m", "ensurepip"])
check_call([join(python27_dir, "python.exe"), "-m", "pip", "install", "--upgrade", "pip"])
# Update setuptools to the latest version.
check_call([join(python27_dir, "python.exe"), "-m", "pip", "install", "--upgrade", "setuptools"])
# Install virtualenv.
check_call([join(python27_dir, "python.exe"), "-m", "pip", "install", "virtualenv"])
# Install Mercurial and copy mercurial.ini to the python dir so Mercurial has sane defaults.
check_call([join(python27_dir, "python.exe"), "-m", "pip", "install", "mercurial"])
copyfile(join(sourcedir, "mercurial.ini"), join(python27_dir, "mercurial.ini"))

# Copy python27.dll to the Scripts directory to work around path detection issues in hg.exe.
# See bug 1415374 for details.
copyfile(join(python27_dir, "python27.dll"), join(python27_dir, r"Scripts\python27.dll"))

# Find any occurrences of hardcoded interpreter paths in the Scripts directory and change them
# to a generic python.exe instead. Awful, but distutils hardcodes the interpreter path in the
# scripts, which breaks because it uses the path on the machine we built this package on, not
# the machine it was installed on. And unfortunately, pip doesn't have a way to pass down the
# --executable flag to override this behavior.
# See http://docs.python.org/distutils/setupscript.html#installing-scripts
def distutils_shebang_fix(path, oldString, newString):
    for dirname, dirs, files in os.walk(path):
        for filename in files:
            filepath = join(dirname, filename)
            with open(filepath, "rb") as f:
                s = f.read()
            s = s.replace(oldString, newString)
            with open(filepath, "wb") as f:
                f.write(s)

distutils_shebang_fix(join(python27_dir, "Scripts"), join(python27_dir, "python.exe"), "python.exe")

# Extract Python 3.6 to the stage directory. The archive being used is the result of running the
# installer in a VM with the command line below and packaging up the resulting directory.
# Unfortunately, there isn't a way to run a fully isolated install on the host machine without
# adding a bunch of registry entries, so this is what we're left doing.
#   <installer> /passive InstallAllUsers=0 TargetDir=c:\python3 Include_launcher=0 Include_test=0 CompileAll=1
# Packaged with 7-Zip using:
#   LZMA2 compression with Ultra compression, 96MB dictionary size, 256 word size, solid archive
print "Staging Python 3.6 and extra packages..."
python36_dir = join(pkgdir, "python3")
check_call(["7z.exe", "x", join(sourcedir, "python-3.6.5.7z"), "-o" + python36_dir])
# Copy python.exe to python3.exe & python3.6.exe.
copyfile(join(python36_dir, "python.exe"), join(python36_dir, "python3.exe"))
copyfile(join(python36_dir, "python.exe"), join(python36_dir, "python3.6.exe"))

# Update the copy of SQLite bundled with Python 3.6.
with zipfile.ZipFile(join(sourcedir, sqlite_file), 'r') as sqlite3_zip:
    sqlite3_zip.extract("sqlite3.dll", join(python36_dir, "DLLs"))

# Update pip to the latest version.
check_call([join(python36_dir, "python3.exe"), "-m", "pip", "install", "--upgrade", "pip"])
# Update setuptools to the latest version.
check_call([join(python36_dir, "python3.exe"), "-m", "pip", "install", "--upgrade", "setuptools"])
# Install virtualenv.
check_call([join(python36_dir, "python3.exe"), "-m", "pip", "install", "virtualenv"])

# Do the shebang fix on Python3 too. Need to special-case c:\python3\python.exe too due to the
# aforementioned packaging issues above.
distutils_shebang_fix(join(python36_dir, "Scripts"), join(r"c:\python3\python.exe"), "python3.exe")
distutils_shebang_fix(join(python36_dir, "Scripts"), join(python36_dir, "python3.exe"), "python3.exe")

# Extract KDiff3 to the stage directory. The KDiff3 installer doesn't support any sort of
# silent installation, so we use a ready-to-extract 7-Zip archive instead.
print "Staging KDiff3..."
check_call(["7z.exe", "x", join(sourcedir, "KDiff3-32bit-Setup_0.9.98.exe"),
            "-o" + join(pkgdir, "kdiff3")])

# Extract Info-Zip Zip & UnZip to the stage directory.
print "Staging Info-Zip..."
with zipfile.ZipFile(join(sourcedir, "unz600xN.exe"), 'r') as unzip_zip:
    unzip_zip.extractall(join(pkgdir, r"bin\info-zip"))
with zipfile.ZipFile(join(sourcedir, "zip300xN.zip"), 'r') as zip_zip:
    zip_zip.extractall(join(pkgdir, r"bin\info-zip"))
# Copy unzip.exe and zip.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\info-zip\unzip.exe"), join(pkgdir, r"bin\unzip.exe"))
copyfile(join(pkgdir, r"bin\info-zip\zip.exe"), join(pkgdir, r"bin\zip.exe"))

# Copy mozmake to the stage directory.
print "Staging mozmake..."
copyfile(join(sourcedir, "mozmake.exe"), join(pkgdir, r"bin\mozmake.exe"))

# Copy nsinstall to the stage directory.
print "Staging nsinstall..."
copyfile(join(sourcedir, "nsinstall.exe"), join(pkgdir, r"bin\nsinstall.exe"))

# Extract NSIS 3.01 to the stage directory.
# Downloaded from https://sourceforge.net/projects/nsis/files/NSIS%203/3.01/nsis-3.01.zip/download
print "Staging NSIS..."
nsis_dir = join(pkgdir, "nsis-3.01")
with zipfile.ZipFile(join(sourcedir, "nsis-3.01.zip"), 'r') as nsis_zip:
    nsis_zip.extractall(pkgdir)
# Rename the NSIS 3.01 command line executables.
os.rename(join(nsis_dir, "makensis.exe"), join(nsis_dir, "makensis-3.01.exe"))
os.rename(join(nsis_dir, r"Bin\makensis.exe"), join(nsis_dir, r"Bin\makensis-3.01.exe"))

# Extract UPX to the stage directory.
print "Staging UPX 3.94..."
with zipfile.ZipFile(join(sourcedir, "upx394w.zip"), 'r') as upx_zip:
    upx_zip.extractall(join(pkgdir, "bin"))
# Copy upx.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\upx394w\upx.exe"), join(pkgdir, r"bin\upx.exe"))

# Copy vswhere to the stage directory.
print "Staging vswhere 2.4.1..."
copyfile(join(sourcedir, "vswhere.exe"), join(pkgdir, r"bin\vswhere.exe"))

# Extract watchman to the stage directory.
print "Staging watchman..."
with zipfile.ZipFile(join(sourcedir, "watchman-ee2cd14e.zip"), 'r') as watchman_zip:
    watchman_zip.extractall(join(pkgdir, r"bin\watchman-ee2cd14e"))
os.remove(join(pkgdir, r"bin\watchman-ee2cd14e\watchman.pdb"))
# Copy watchman.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\watchman-ee2cd14e\watchman.exe"), join(pkgdir, r"bin\watchman.exe"))

# Extract wget to the stage directory.
# Downloaded from https://eternallybored.org/misc/wget/
print "Staging wget 1.19.4..."
with zipfile.ZipFile(join(sourcedir, "wget-1.19.4-win64.zip"), 'r') as wget_zip:
    wget_zip.extractall(join(pkgdir, r"bin\wget-1.19.4"))
os.remove(join(pkgdir, r"bin\wget-1.19.4\wget.exe.gdb"))
# Copy wget.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\wget-1.19.4\wget.exe"), join(pkgdir, r"bin\wget.exe"))

# Extract yasm to the stage directory.
# Includes a bundled copy of msvcr100.dll to avoid missing runtime errors on some systems.
print "Staging yasm 1.3.0..."
with zipfile.ZipFile(join(sourcedir, "yasm-1.3.0-win64.zip"), 'r') as yasm_zip:
    yasm_zip.extractall(join(pkgdir, "bin"))

# Extract MSYS packages to the stage directory.
print "Extracting MSYS components..."
msysdir = join(pkgdir, "msys")
if not os.path.exists(msysdir):
    os.mkdir(msysdir)
for archive in glob.glob(join(sourcedir, "msys", "*.lzma")):
    print "    " + archive
    check_call(["tar", "--lzma", "--force-local", "-xf", join(sourcedir, "msys", archive)], cwd=msysdir)

# mktemp.exe extracts as read-only, which breaks manifest embedding later.
os.chmod(join(msysdir, r"bin\mktemp.exe"), 0755)

# Extract emacs to the stage directory.
print "Staging emacs..."
check_call(["tar", "--lzma", "--force-local", "-xf", join(sourcedir, "emacs-25.3_1-x86_64.tar.lzma")], cwd=msysdir)

# Replace the native MSYS rm with winrm.
print "Replacing MSYS rm with winrm..."
os.rename(join(msysdir, r"bin\rm.exe"), join(msysdir, r"bin\rm-msys.exe"))
copyfile(join(sourcedir, "winrm.exe"), join(msysdir, r"bin\rm.exe"))
copyfile(join(sourcedir, "winrm.exe"), join(msysdir, r"bin\winrm.exe"))

# Copy the vi shell script to the bin dir.
copyfile(join(sourcedir, r"msys\misc\vi"), join(msysdir, r"bin\vi"))

# Copy over CA certificates in PEM format (converted from Firefox's defaults) so SSL will work.
# This is used by both Mercurial and wget.
copyfile(join(sourcedir, "ca-bundle.crt"), join(msysdir, r"etc\ca-bundle.crt"))

# Copy various configuration files.
print "Copying various configuration files..."
for file in ["inputrc", "minttyrc"]:
    copyfile(join(sourcedir, r"msys\misc", file), join(msysdir, "etc", file))

copyfile(join(sourcedir, r"msys\misc\ssh_config"), join(msysdir, r"etc\ssh\ssh_config"))

if not os.path.exists(join(msysdir, "etc", "profile.d")):
    os.mkdir(join(msysdir, "etc", "profile.d"))
for file in ["profile-inputrc.sh", "profile-extravars.sh", "profile-echo.sh", "profile-homedir.sh", "profile-sshagent.sh"]:
    copyfile(join(sourcedir, r"msys\misc", file), join(msysdir, r"etc\profile.d", file))

# Recursively find all MSYS DLLs, then chmod them to make sure none are read-only.
# Then rebase them via the editbin tool.
print "Rebasing MSYS DLLs..."
def editbin(file_list, base):
    check_call([join(tools_path, "editbin.exe"), "/REBASE:BASE=" + base, "/DYNAMICBASE:NO"] + file_list)

tools_version = open(join(vsdir, r"VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt"), "rb").read().strip()
tools_path = join(vsdir, r"VC\Tools\MSVC", tools_version, r"bin\HostX64\x64")
dll_list = []
for rootdir, dirnames, filenames in os.walk(msysdir):
    for file in filenames:
        if file.endswith(".dll"):
            dll = join(rootdir, file)
            os.chmod(dll, 755)
            dll_list.append(dll)

editbin(dll_list, "0x60000000,DOWN")
# msys-1.0.dll is special and needs to be rebased independent of the rest
editbin([join(msysdir, r"bin\msys-1.0.dll")], "0x60100000")

# Embed some manifests to make UAC happy.
print "Embedding manifests in executable files..."
def embedmanifest(f, mf):
    f = os.path.abspath(f)
    check_call([join(sdkdir, "mt.exe"), "-manifest", mf, '-outputresource:%s;#1' % f])

def embed_recursedir(dir, mf):
    for rootdir, dirnames, filenames in os.walk(dir):
        for f in filenames:
            if f.endswith(".exe"):
                embedmanifest(join(rootdir, f), mf)

manifest = join(sourcedir, "noprivs.manifest")
embed_recursedir(msysdir, manifest)

# Copy some miscellaneous files to the root directory.
print "Copying a few miscellaneous files..."
copyfile(join(sourcedir, "start-shell.bat"), join(pkgdir, "start-shell.bat"))
copyfile(join(sourcedir, "VERSION"), join(pkgdir, "VERSION"))

# Package the installer.
print "Packaging everything up into the installer..."
for file in ["helpers.nsi", "installit.nsi", "license.rtf"]:
    copyfile(join(sourcedir, file), join(stagedir, file))
# Write the real version number to installit.nsi in the stage directory.
with open(join(stagedir, 'installit.nsi'), 'rb') as fh:
   lines = fh.readlines()
with open(join(stagedir, 'installit.nsi'), 'wb') as fh:
   for line in lines:
       fh.write(line.replace('@VERSION@', version))
check_call(["makensis-3.01.exe", "/NOCD", "installit.nsi"], cwd=stagedir)
