#!python.exe

# Create a MozillaBuild installer.
#
# This packaging script is intended to be entirely self-contained. However, it's within the realm
# of possibility of making changes to the host machine it's running on, so it's recommmended to
# be run within a VM instead.
#
# System Requirements:
#   * 64-bit host OS
#   * Windows 7+
#   * Existing MozillaBuild installation
#
# Usage Instructions:
#   The script has built-in defaults that should allow for the package to be built simply by
#   invoking ./packageit.py from a MozillaBuild terminal. It also supports command line arguments
#   for changing the default paths if desired.
#

from subprocess import check_call
from os import getcwd, remove, environ, chdir, walk, rename, remove
from os.path import dirname, join, split, abspath, exists
from shutil import rmtree, copyfile, copytree
import distutils.core, optparse, tarfile, urllib2

# Set default values for the source and stage directories.
sourcedir = join(split(abspath(__file__))[0])
stagedir = "c:\\mozillabuild-stage"

# Override the source and/or stage directory locations if otherwise specified.
oparser = optparse.OptionParser()
oparser.add_option("-s", "--source", dest="sourcedir")
oparser.add_option("-o", "--output", dest="stagedir")
(options, args) = oparser.parse_args()

if len(args) != 0:
    raise Exception("Unexpected arguments passed to command line.")

if options.sourcedir:
    sourcedir = options.sourcedir
if options.stagedir:
    stagedir = options.stagedir

environ["MOZ_STAGEDIR"] = stagedir
environ["MOZ_SRCDIR"] = sourcedir

print("Source location: " + sourcedir)
print("Output location: " + stagedir)

# Remove the old stage directory if it's already present.
# We use cmd.exe instead of sh.rmtree because it's more forgiving of open handles than
# Python is (i.e. not hard-stopping if you happen to have the stage directory open in
# Windows Explorer while testing.
if exists(stagedir):
    check_call(["cmd.exe", "/C", "rmdir /S /Q %s" % stagedir])

# Install 7-Zip. Create an administrative install point and copy the files to stage rather
# than using a silent install to avoid installing the shell extension on the host machine.
check_call(["msiexec.exe", "/q", "/a",
            join(sourcedir, "7z1604.msi"),
            "TARGETDIR=" + join(stagedir, "7zip")])
copytree(join(stagedir, "7zip", "Files", "7-Zip"),
         join(stagedir, "mozilla-build", "7zip"))

# Install Python
python_installer = "python-2.7.13.msi"
check_call(["msiexec.exe", "/q", "/a",
            join(sourcedir, python_installer),
            "TARGETDIR=" + join(stagedir, "mozilla-build", "python")])
# Copy python.exe to python2.exe & python2.7.exe and remove the MSI
copyfile(join(stagedir, "mozilla-build", "python", "python.exe"),
         join(stagedir, "mozilla-build", "python", "python2.exe"))
copyfile(join(stagedir, "mozilla-build", "python", "python.exe"),
         join(stagedir, "mozilla-build", "python", "python2.7.exe"))
remove(join(stagedir, "mozilla-build", "python", python_installer))

# Run ensurepip and update to the latest version
check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
            "-m", "ensurepip"])
check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
            "-m", "pip", "install", "--upgrade", "pip"])
# Update setuptools to the latest version
check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
            "-m", "pip", "install", "--upgrade", "setuptools"])
# Install hgwatchman - TEMPORARILY COMMENTED OUT DUE TO BUSTAGE
#check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
#            "-m", "pip", "install", "hgwatchman"])
# Install virtualenv
check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
            "-m", "pip", "install", "virtualenv"])
# Install Mercurial
check_call([join(stagedir, "mozilla-build", "python", "python.exe"),
            "-m", "pip", "install", "mercurial"])

# Find any occurrences of hardcoded interpreter paths in the Scripts directory and change them
# to a generic python.exe instead. Awful, but distutils hardcodes the interpreter path in the
# scripts, which breaks because it uses the path on the machine we built this package on, not
# the machine it was installed on. And unfortunately, pip doesn't have a way to pass down the
# --executable flag to override this behavior.
# See http://docs.python.org/distutils/setupscript.html#installing-scripts
def distutils_shebang_fix(path, oldString, newString):
    for dirname, dirs, files in walk(path):
        for filename in files:
            filepath = join(dirname, filename)
            with open(filepath, "rb") as f:
                s = f.read()
            s = s.replace(oldString, newString)
            with open(filepath, "wb") as f:
                f.write(s)
distutils_shebang_fix(join(stagedir, "mozilla-build", "python", "Scripts"),
                      join(stagedir, "mozilla-build", "python", "python.exe"),
                      "python.exe")

# Extract KDiff3 to the stage directory. The KDiff3 installer doesn't support any sort of
# silent installation, so we use a ready-to-extract 7-Zip archive instead.
check_call(["7z.exe", "x", join(sourcedir, "KDiff3-32bit-Setup_0.9.98.exe"),
            "-o" + join(stagedir, "mozilla-build", "kdiff3")])

# Run an MSYS shell to perform the following tasks:
# * Extract MSYS packages and rebase DLLs
# * Install other packages (UPX, info-zip, etc)
check_call(["sh.exe", join(sourcedir, "packageit.sh")])

# Embed some manifests to make Vista happy
def embedmanifest(f, mf):
    f = abspath(f)
    check_call(["mt.exe", "-manifest", mf,
                '-outputresource:%s;#1' % f])

def embed_recursedir(dir, mf):
    for rootdir, dirnames, filenames in walk(dir):
        for f in filenames:
            if f.endswith(".exe"):
                embedmanifest(join(rootdir, f), mf)

manifest = join(sourcedir, "noprivs.manifest")
embed_recursedir(join(stagedir, "mozilla-build", "msys"), manifest)
embedmanifest(join(stagedir, "mozilla-build", "moztools", "bin", "nsinstall.exe"), manifest)

# Make an installer
chdir(stagedir)
check_call(["makensis", "/NOCD", "installit.nsi"])
