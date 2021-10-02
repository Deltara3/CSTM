from sys import argv
from subprocess import getoutput
from platform import system
from pathlib import Path
from json import loads

subcommands = ["install", "uninstall", "publish", "unpublish"]
ver = 'v0.1.0-dev'
flags = argv[-1]

# Get libraries path
if system() in ["Linux", "Darwin"]:
    res = getoutput("which spwn")
    if Path(res).is_symlink() == True:
        libraries_root = f"{str(Path(res).resolve())[:-4]}libraries/"
    else:
        libraries_root = f"{res[:-4]}libraries/"
elif system() == "Windows":
    libraries_root = f"{getoutput('where spwn')[:-4]}libraries/"

# Argument shit
if len(argv) == 1:
    print("Usage: cstm [subcommand] (package)\n\nSubcommands:\n     version\n     Returns CSTM's version number\n\n     install [package]\n     Installs a package\n\n     uninstall [package]\n     Uninstalls a package\n\n     publish [cstmbuild]\n     Publishes a package's CSTMBUILD\n\n     unpublish [package]\n     Unpublishes a package's CSTMBUILD\n\nFlags:\n     --local\n     Allows using a local CSTMBUILD when installing\n")
    exit()

if argv[1] == "version":
    print(f"CSTM {ver}")
    exit()

if argv[1] == "install":
    if "--local" in flags:
        try:
            build = open(argv[2], "r")
            contents = build.read()
            build.close()
            print(loads(contents))
        except FileNotFoundError:
            print(f"Fatal Error: File \"{argv[2]}\" could not be found.")
            exit()
