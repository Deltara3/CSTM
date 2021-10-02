import requests
from sys import argv
from subprocess import getoutput
from platform import system
from pathlib import Path
from json import loads
from shutil import rmtree
from os import path, chdir

packages = argv[2:]
subcommands = ["install", "uninstall", "publish", "unpublish"]
cstm_ver = 'v0.1.0-dev'
try:
    spwn_ver = getoutput("spwn version")
except:
    spwn_ver = "N/A"
flags = argv[-1]
base_url = "https://raw.githubusercontent.com/Deltara3/cstm-main/main/"

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
    print("Usage: cstm [subcommand] (package)\n\nSubcommands:\n     version\n     Returns CSTM's version number\n\n     install [package(s)]\n     Installs a package\n\n     uninstall [package(s)]\n     Uninstalls a package\n\n     update (package(s))\n     Updates packages\n\n     publish [cstmbuild]\n     Publishes a package's CSTMBUILD\n\n     unpublish [package]\n     Unpublishes a package's CSTMBUILD\n")
    exit()

if argv[1] == "version":
    print(f"CSTM {cstm_ver}\nSPWN {spwn_ver}")
    exit()

if argv[1] == "install":
    packages_db = []
    depends_db = []
    packages_ls = []
    depends_ls = []
    redo = True
    for i in packages:
        res = requests.get(f"{base_url}{i}")
        if res.status_code == 200:
            build = loads(res.text)
            packages_db.append(build)
        else:
            print(f"Error: Package \"{i}\" not found.")
            exit()
    for i in packages_db:
        packages_ls.append(f"{i['id']} -> {i['version']}")
        if "depends" in i:
            for i in i["depends"]:
                res = requests.get(f"{base_url}{i}")
                if res.status_code == 200:
                    build = loads(res.text)
                    if i in depends_db:
                        pass
                    else:
                        depends_db.append(build)
                else:
                    print(f"Error: Package \"{i}\" not found.")
                    quit()
    for i in depends_db:
        if "depends" in i:
            for i in i["depends"]:
                res = requests.get(f"{base_url}{i}")
                if res.status_code == 200:
                    build = loads(res.text)
                    if build in depends_db:
                        pass
                    else:
                        depends_db.append(build)
                else:
                    print(f"Error: Package \"{i}\" not found.")
                    quit()
    for i in depends_db:
        if f"{i['id']} -> {i['version']}" in packages_ls:
            pass
        else:
            depends_ls.append(f"{i['id']} -> {i['version']}")
    if len(depends_ls) != 0:
        print(f":: Dependencies to be installed:")
        print("\n".join(depends_ls)+"\n")
    print(f":: Package(s) to be installed:")
    print("\n".join(packages_ls)+"\n\n:: Proceed? [Y/n]")
    sel = input(">>> ")
    if len(sel) == 0 or sel == "y" or sel == "Y":
        for i in packages_db:
            if i in depends_db:
                depends_db.remove(i)
        chdir(libraries_root)
        for i in packages_db:
            if "type" in i:
                package_type = i["type"]
            else:
                package_type = "git"
            print(f":> Installing \"{i['id']}\", please wait.")
            if package_type == "git":
                getoutput(f"git clone {i['source']} {i['id']}")
                if path.isdir(f"{libraries_root}{i['id']}") == False:
                    print(f"Error: Failed to install package \"{i['id']}\", no permission.")
        if len(depends_db) != 0:
            for i in depends_db:
                if "type" in i:
                    package_type = i["type"]
                else:
                    package_type = "git"
                print(f":> Installing \"{i['id']}\", please wait.")
                if package_type == "git":
                    getoutput(f"git clone {i['source']} {i['id']}")
                    if path.isdir(f"{libraries_root}{i['id']}") == False:
                        print(f"Error: Failed to install package \"{i['id']}\", no permission.")
    elif sel == "n" or sel == "N":
        quit()
    else:
        quit()
if argv[1] == "uninstall":
    if argv[2] in ["std", "gamescene"]:
        print(f"Error: \"{argv[2]}\" is a builtin library, refusing to uninstall.")
        exit()
    else:
        packages_new = []
        for i in packages:
            if path.isdir(f"{libraries_root}{i}"):
                packages_new.append(i)
            else:
                print(f"Error: Package \"{i}\" not installed.")
                exit()
        print(f":: Package(s) to be uninstalled:")
        print("\n".join(packages_new)+"\n\n:: Proceed? [y/N]")
        sel = input(">>> ")
        if sel == 0 or sel == "n" or sel == "N":
            quit()
        elif sel == "y" or sel == "Y":
            try:
                for i in packages_new:
                    rmtree(f"{libraries_root}{i}")
            except PermissionError:
                print(f"Error: Failed to uninstall package \"{i}\", no permission.")
                exit()
        else:
            quit()

if argv[1] == "update":
    print("Error: Not implemented yet.")
    quit()

if argv[1] == "publish":
    print("Error: Not implemented yet.")
    quit()

if argv[1] == "unpublish":
    print("Error: Not implemented yet.")
    quit()