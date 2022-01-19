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

from multiprocessing.pool import ThreadPool
from os.path import join
from pathlib import Path
from shutil import copyfile, copytree
from subprocess import check_call, check_output
import optparse, os, os.path, zipfile
import winreg
import requests
from textwrap import dedent


def get_vs_path():
    def vswhere(property):
        return check_output(
            ["vswhere", "-products", "*", "-format", "value", "-property", property]
        ).decode("mbcs", "replace")

    return vswhere("installationPath").rstrip()


def get_sdk_path():
    sdk_key = winreg.OpenKey(
        winreg.HKEY_LOCAL_MACHINE,
        r"SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0",
    )
    sdk_dir = winreg.QueryValueEx(sdk_key, "InstallationFolder")[0]
    sdk_version = winreg.QueryValueEx(sdk_key, "ProductVersion")[0] + ".0"

    return join(sdk_dir, "bin", sdk_version, "x64")


# Set default values for the source and stage directories.
sourcedir = join(os.path.split(os.path.abspath(__file__))[0])
stagedir = r"c:\mozillabuild-stage"
vsdir = get_vs_path()
sdkdir = get_sdk_path()
msys2refdir = r"c:\msys64"

# Override the source and/or stage directory locations if otherwise specified.
oparser = optparse.OptionParser()
oparser.add_option(
    "-s", "--source", dest="sourcedir", help="Path to the MozillaBuild source."
)
oparser.add_option(
    "-o", "--output", dest="stagedir", help="Path to the desired staging directory."
)
oparser.add_option(
    "-v",
    "--visual-studio",
    dest="vsdir",
    help="Path to the Visual Studio installation.",
)
oparser.add_option(
    "-w", "--winsdk", dest="sdkdir", help="Path to the Windows SDK installation."
)
oparser.add_option(
    "-m",
    "--msys2",
    dest="msys2refdir",
    help="Path to the reference MSYS2 installation.",
)
oparser.add_option(
    "--fetch-sources",
    action="store_true",
    help='Download sources for MSYS2 package and put them in "<staging-directory>/src/". '
    "Off by default for packaging-performance reasons.",
)
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
if options.msys2refdir:
    msys2refdir = options.msys2refdir

fetch_sources = bool(options.fetch_sources)
pkgdir = join(stagedir, "mozilla-build")

# Read the version number
with open(join(sourcedir, "VERSION")) as f:
    version = f.read().splitlines()[0]

print("*****************************************")
print("Packaging MozillaBuild version: " + version)
print("*****************************************")
print("")
print("Reference MSYS2 installation location: " + msys2refdir)
print("Visual Studio location: " + vsdir)
print("Windows SDK location: " + sdkdir)
print("Source location: " + sourcedir)
print("Output location: " + stagedir)
print("Fetch sources: " + str(fetch_sources))
print("")

pacman = join(msys2refdir, "usr", "bin", "pacman.exe")
assert os.path.isfile(pacman), (
    f'Reference MSYS2 installation is invalid - "pacman" '
    f'doesn\'t exist at "{pacman}"'
)

# Remove the old stage directory if it's already present.
# We use cmd.exe instead of sh.rmtree because it's more forgiving of open handles than
# Python is (i.e. not hard-stopping if you happen to have the stage directory open in
# Windows Explorer while testing.
print("Removing the old stage directory..." + "\n")
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
print("Staging 7-Zip...")
check_call(
    [
        "msiexec.exe",
        "/q",
        "/a",
        join(sourcedir, "7z1805-x64.msi"),
        "TARGETDIR=" + join(stagedir, "7zip"),
    ]
)
copytree(join(stagedir, r"7zip\Files\7-Zip"), join(pkgdir, r"bin\7zip"))
# Copy 7z.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\7zip\7z.exe"), join(pkgdir, r"bin\7z.exe"))
copyfile(join(pkgdir, r"bin\7zip\7z.dll"), join(pkgdir, r"bin\7z.dll"))

# Install Python 2.7 in the stage directory. Create an administrative install point to avoid
# polluting the host machine along the way.
print("Staging Python 2.7 and extra packages...")
python27_dir = join(pkgdir, "python")
python_installer = "python-2.7.17.amd64.msi"
check_call(
    [
        "msiexec.exe",
        "/q",
        "/a",
        join(sourcedir, python_installer),
        "TARGETDIR=" + python27_dir,
    ]
)
# Copy python.exe to python2.exe & python2.7.exe and remove the MSI.
copyfile(join(python27_dir, "python.exe"), join(python27_dir, "python2.exe"))
copyfile(join(python27_dir, "python.exe"), join(python27_dir, "python2.7.exe"))
os.remove(join(python27_dir, python_installer))

# Update the copy of SQLite bundled with Python 2.
sqlite_file = "sqlite-dll-win64-x64-3250200.zip"
with zipfile.ZipFile(join(sourcedir, sqlite_file), "r") as sqlite3_zip:
    sqlite3_zip.extract("sqlite3.dll", join(python27_dir, "DLLs"))

# Run ensurepip and update to the latest version.
check_call([join(python27_dir, "python.exe"), "-m", "ensurepip"])
check_call(
    [join(python27_dir, "python.exe"), "-m", "pip", "install", "--upgrade", "pip"]
)
# Update setuptools to the latest version.
check_call(
    [
        join(python27_dir, "python.exe"),
        "-m",
        "pip",
        "install",
        "--upgrade",
        "setuptools",
    ]
)
# Install Mercurial and copy mercurial.ini to the python dir so Mercurial has sane defaults.
check_call(
    [
        join(python27_dir, "python.exe"),
        "-m",
        "pip",
        "install",
        "mercurial",
        "windows-curses",
    ]
)
copyfile(join(sourcedir, "mercurial.ini"), join(python27_dir, "mercurial.ini"))

# Copy python27.dll to the Scripts directory to work around path detection issues in hg.exe.
# See bug 1415374 for details.
copyfile(
    join(python27_dir, "python27.dll"), join(python27_dir, r"Scripts\python27.dll")
)

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


distutils_shebang_fix(
    join(python27_dir, "Scripts"), join(python27_dir, "python.exe").encode("utf-8"), b"python2.7.exe"
)

# Extract Python3 to the stage directory. The archive being used is the result of running the
# installer in a VM with the command line below and packaging up the resulting directory.
# Unfortunately, there isn't a way to run a fully isolated install on the host machine without
# adding a bunch of registry entries, so this is what we're left doing.
#   <installer> /passive TargetDir=c:\python3 Include_launcher=0 Include_test=0 CompileAll=1 Shortcuts=0
# Packaged with 7-Zip using:
#   LZMA2 compression with Ultra compression, 96MB dictionary size, 256 word size, solid archive
# or from the command line (only need to specify ultra compression here):
#   $ cd /c/python3 && 7z a /c/temp/python-3.x.x.7z -r . -mx=9
print("Staging Python 3.7 and extra packages...")
python3_dir = join(pkgdir, "python3")
check_call(["7z.exe", "x", join(sourcedir, "python-3.9.9.7z"), "-o" + python3_dir])
# Copy python.exe to python3.exe.
copyfile(join(python3_dir, "python.exe"), join(python3_dir, "python3.exe"))

check_call(["patch", join(python3_dir, "Lib", "venv", "__init__.py"), join(sourcedir, "python3-venv-winerror.patch")])

# Update pip to the latest version.
check_call(
    [join(python3_dir, "python3.exe"), "-m", "pip", "install", "--upgrade", "pip"]
)
# Update setuptools to the latest version.
check_call(
    [
        join(python3_dir, "python3.exe"),
        "-m",
        "pip",
        "install",
        "--upgrade",
        "setuptools",
    ]
)
# Do the shebang fix on Python3 too. Need to special-case c:\python3\python.exe too due to the
# aforementioned packaging issues above.
distutils_shebang_fix(
    join(python3_dir, "Scripts"), rb"c:\python3\python.exe", b"python3.exe"
)
distutils_shebang_fix(
    join(python3_dir, "Scripts"), join(python3_dir, "python3.exe").encode("utf-8"), b"python3.exe"
)

# Extract KDiff3 to the stage directory. The KDiff3 installer doesn't support any sort of
# silent installation, so we use a ready-to-extract 7-Zip archive instead.
print("Staging KDiff3...")
check_call(
    [
        "7z.exe",
        "x",
        join(sourcedir, "KDiff3-32bit-Setup_0.9.98.exe"),
        "-o" + join(pkgdir, "kdiff3"),
    ]
)

# Extract Info-Zip Zip & UnZip to the stage directory.
print("Staging Info-Zip...")
with zipfile.ZipFile(join(sourcedir, "unz600xN.exe"), "r") as unzip_zip:
    unzip_zip.extractall(join(pkgdir, r"bin\info-zip"))
with zipfile.ZipFile(join(sourcedir, "zip300xN.zip"), "r") as zip_zip:
    zip_zip.extractall(join(pkgdir, r"bin\info-zip"))
# Copy unzip.exe and zip.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\info-zip\unzip.exe"), join(pkgdir, r"bin\unzip.exe"))
copyfile(join(pkgdir, r"bin\info-zip\zip.exe"), join(pkgdir, r"bin\zip.exe"))

# Copy nsinstall to the stage directory.
print("Staging nsinstall...")
copyfile(join(sourcedir, "nsinstall.exe"), join(pkgdir, r"bin\nsinstall.exe"))


# Extract UPX to the stage directory.
print("Staging UPX 3.95...")
with zipfile.ZipFile(join(sourcedir, "upx-3.95-win64.zip"), "r") as upx_zip:
    upx_zip.extractall(join(pkgdir, "bin"))
# Copy upx.exe to the main bin directory to make our PATH bit more tidy
copyfile(join(pkgdir, r"bin\upx-3.95-win64\upx.exe"), join(pkgdir, r"bin\upx.exe"))

# Copy vswhere to the stage directory.
print("Staging vswhere 2.5.2...")
copyfile(join(sourcedir, "vswhere.exe"), join(pkgdir, r"bin\vswhere.exe"))

# Extract watchman to the stage directory.
print("Staging watchman...")
with zipfile.ZipFile(join(sourcedir, "watchman-v2021.01.11.00.zip"), "r") as watchman_zip:
    # Copy to the main bin directory to make our PATH bit more tidy
    watchman_zip.extractall(join(pkgdir, r"bin"))
# Distribute license with watchman as mandated by MIT.
copyfile(
    join(sourcedir, "watchman-LICENSE"),
    join(pkgdir, r"bin\watchman-LICENSE"),
)

print("Locating MSYS2 components and dependencies...")
required_msys2_package_names = [
    "bash",
    "bash-completion",
    "bzip2",
    "ca-certificates",
    "coreutils",
    "diffutils",
    "file",
    "filesystem",
    "findutils",
    "gawk",
    "grep",
    "gzip",
    "less",
    "m4",
    "mintty",
    "nano",
    "openssh",
    "patch",
    "perl",
    "sed",
    "tar",
    "vim",
    "xz",
    "which",
]

# Extract MSYS2 packages to the stage directory.
print("Extracting MSYS2 components...")
msysdir = join(pkgdir, "msys2")
os.makedirs(join(msysdir, "tmp"))
os.makedirs(join(msysdir, "var", "lib", "pacman"))
os.makedirs(join(msysdir, "var", "log"))

env_with_msys2_path = os.environ.copy()
env_with_msys2_path["PATH"] = (
    f"{msys2refdir}/usr/bin" + os.pathsep + env_with_msys2_path["PATH"]
)

check_call(
    [
        pacman,
        "-S",
        "--refresh",
        "--noconfirm",
        "--root",
        msysdir,
        # Install msys2-runtime first so that post-install scripts run successfully
        "msys2-runtime",
        *required_msys2_package_names,
    ],
    env=env_with_msys2_path,
)

if fetch_sources:
    print("Downloading MSYS2 package sources...")

    msys_src_packages_dir = join(stagedir, "src")
    os.mkdir(msys_src_packages_dir)
    output = check_output(
        [pacman, "-Q", "--root", msysdir],
        universal_newlines=True,
    )
    urls = [
        f"https://repo.msys2.org/msys/sources/{name}-{version}.src.tar.gz"
        for name, version in (line.split(" ") for line in output.splitlines())
    ]

    def download_file(url):
        print(f"  Downloading {url}")
        response = requests.get(url, stream=True)
        with open(os.path.join(msys_src_packages_dir, Path(url).name), "wb") as file:
            for chunk in response.iter_content(chunk_size=16*1024):
                file.write(chunk)

    pool = ThreadPool(8)
    pool.imap_unordered(download_file, urls)
    pool.close()
    pool.join()

# db_home: Set "~" to point to "%USERPROFILE%"
# db_gecos: Fills out gecos information (such as the user's full name) from AD/SAM.
with open(join(msysdir, r"etc\nsswitch.conf"), "w") as nsswitch_conf:
    nsswitch_conf.write(
        dedent(
            """
        db_home: windows
        db_gecos: windows
        """
        )
    )

# We won't be including the package manager (pacman), so remove its key management setup.
os.remove(join(msysdir, r"etc\post-install\07-pacman-key.post"))
# We don't install the xmlcatalog binary.
os.remove(join(msysdir, r"etc\post-install\08-xml-catalog.post"))

# Extract emacs to the stage directory.
print("Staging emacs...")
check_call(
    [
        join(msys2refdir, "usr", "bin", "tar.exe"),
        "--lzma",
        "--force-local",
        "-xf",
        join(sourcedir, "emacs-26.3-x86_64-no-deps.tar.lzma"),
    ],
    cwd=join(msysdir, "usr"),
    # Use "env_with_msys2_path" so that "tar" can find "xz"/"zstd"
    env=env_with_msys2_path,
)

# Replace the native MSYS rm with winrm.
print("Replacing MSYS rm with winrm...")
os.rename(join(msysdir, r"usr\bin\rm.exe"), join(msysdir, r"usr\bin\rm-msys.exe"))
copyfile(join(sourcedir, "winrm.exe"), join(msysdir, r"usr\bin\rm.exe"))
copyfile(join(sourcedir, "winrm.exe"), join(msysdir, r"usr\bin\winrm.exe"))

with open(join(msysdir, r"usr\bin\vi"), "w") as vi:
    vi.write(
        dedent(
            """
        #!/bin/sh
        exec vim "$@"
    """.strip()
        )
    )

# Copy various configuration files.
print("Copying various configuration files...")
copyfile(
    join(sourcedir, r"msys-config\ssh_config"), join(msysdir, r"etc\ssh\ssh_config")
)

if not os.path.exists(join(msysdir, "etc", "profile.d")):
    os.mkdir(join(msysdir, "etc", "profile.d"))
copyfile(
    join(sourcedir, "msys-config", "profile-mozilla.sh"),
    join(msysdir, r"etc\profile.d", "profile-mozilla.sh"),
)

# Recursively find all MSYS DLLs, then chmod them to make sure none are read-only.
# Then rebase them via the editbin tool.
print("Rebasing MSYS DLLs...")


def editbin(file_list, base, cwd=None):
    check_call(
        [join(tools_path, "editbin.exe"), "/REBASE:BASE=" + base, "/DYNAMICBASE:NO"]
        + file_list,
        cwd=cwd,
    )


tools_version = (
    open(join(vsdir, r"VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt"), "r")
    .read()
    .strip()
)
tools_path = join(vsdir, r"VC\Tools\MSVC", tools_version, r"bin\HostX64\x64")
msys_dlls = {}
for rootdir, dirnames, filenames in os.walk(msysdir):
    for file in filenames:
        if file.endswith(".dll"):
            abs_dll = join(rootdir, file)
            os.chmod(abs_dll, 0o755)
            relative_dll = os.path.relpath(abs_dll, msysdir)
            if file not in msys_dlls:
                # "msys-perl5_32.dll" is in both "/usr/bin/" and "/usr/lib/perl5/...".
                # Since "editbin /rebase" fails if it's provided equivalent dlls, let's
                # ensure no two dlls with the same name are added.
                msys_dlls[file] = relative_dll

editbin(list(msys_dlls.values()), "0x60000000,DOWN", msysdir)
# msys-2.0.dll is special and needs to be rebased independent of the rest
editbin([join(msysdir, r"usr\bin\msys-2.0.dll")], "0x60100000")

# Embed some manifests to make UAC happy.
print("Embedding manifests in executable files...")


def embedmanifest(f, mf):
    f = os.path.abspath(f)
    check_call([join(sdkdir, "mt.exe"), "-manifest", mf, "-outputresource:%s;#1" % f])


def embed_recursedir(dir, mf):
    for rootdir, dirnames, filenames in os.walk(dir):
        for f in filenames:
            if f.endswith(".exe"):
                embedmanifest(join(rootdir, f), mf)


manifest = join(sourcedir, "noprivs.manifest")
embed_recursedir(msysdir, manifest)

# Copy some miscellaneous files to the root directory.
print("Copying a few miscellaneous files...")
copyfile(join(sourcedir, "start-shell.bat"), join(pkgdir, "start-shell.bat"))
copyfile(join(sourcedir, "VERSION"), join(pkgdir, "VERSION"))

# Package the installer.
print("Packaging everything up into the installer...")
for file in ["helpers.nsi", "installit.nsi", "license.rtf"]:
    copyfile(join(sourcedir, file), join(stagedir, file))
# Write the real version number to installit.nsi in the stage directory.
with open(join(stagedir, "installit.nsi"), "r") as fh:
    lines = fh.readlines()
with open(join(stagedir, "installit.nsi"), "w") as fh:
    for line in lines:
        fh.write(line.replace("@VERSION@", version))

# Extract NSIS 3.08 to the stage directory.
# Downloaded from https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08.zip/download
print("Packaging with NSIS...")
with zipfile.ZipFile(join(sourcedir, "nsis-3.08.zip"), "r") as nsis_zip:
    nsis_zip.extractall(stagedir)
makensis_path = os.path.join(stagedir, "nsis-3.08", "makensis.exe")
check_call([makensis_path, "/NOCD", "installit.nsi"], cwd=stagedir)
