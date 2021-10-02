import requests
import zipfile
from sys import argv, executable
from subprocess import getoutput
from platform import system
from pathlib import Path
from urllib import request
from json import loads, dumps
from shutil import rmtree
from os import path, chdir, remove

if "--no-confirm" in argv:
    packages = argv[2:][:-1]
    no_confirm = True
else:
    packages = argv[2:]
    no_confirm = False
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
    print("Usage: cstm [subcommand] (package)\n\nSubcommands:\n     version\n     Returns CSTM's version number\n\n     install [package(s)]\n     Installs a package\n\n     uninstall [package(s)]\n     Uninstalls a package\n\n     update <package(s)>\n     Updates packages\n\n     publish [cstmbuild]\n     Publishes a package's CSTMBUILD\n\n     unpublish [package]\n     Unpublishes a package's CSTMBUILD\n")
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
    if no_confirm == False:
        sel = input(">>> ")
    else:
        sel = "no_confirm"
    if len(sel) == 0 or sel == "y" or sel == "Y" or no_confirm == True:
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
            elif package_type == "zip":
                try:
                    request.urlretrieve(i["source"], "temp_package.zip")
                except PermissionError:
                    print(f"Error: Failed to install package \"{i['id']}\", no permission.")
                    quit()
                with zipfile.ZipFile("temp_package.zip", "r") as package:
                    package.extractall(".")
                remove("temp_package.zip")
            if path.isfile(f"{libraries_root}.ver_db") == False:
                init_ver_db = open(f"{libraries_root}.ver_db", "w")
                init_ver_db.write(dumps({"base": "base"}))
                init_ver_db.close()
            read_version_db = open(".ver_db", "r")
            ver_db_dict = loads(read_version_db.read())
            read_version_db.close()
            version_db = open(".ver_db", "w")
            ver_db_dict[i["id"]] = i["version"]
            version_db.write(dumps(ver_db_dict))
            version_db.close()

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
                        quit()
                elif package_type == "zip":
                    try:
                        request.urlretrieve(i["source"], "temp_package.zip")
                    except PermissionError:
                        print(f"Error: Failed to install package \"{i['id']}\", no permission.")
                        quit()
                    with zipfile.ZipFile("temp_package.zip", "r") as package:
                        package.extractall(".")
                    remove("temp_package.zip")
                if path.isfile(f"{libraries_root}.ver_db") == False:
                    init_ver_db = open(f"{libraries_root}.ver_db", "w")
                    init_ver_db.write(dumps({"base": "base"}))
                    init_ver_db.close()
                read_version_db = open(".ver_db", "r")
                ver_db_dict = loads(read_version_db.read())
                read_version_db.close()
                version_db = open(".ver_db", "w")
                ver_db_dict[i["id"]] = i["version"]
                version_db.write(dumps(ver_db_dict))
                version_db.close()
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
        if no_confirm == False:
            sel = input(">>> ")
        else:
            sel = "no_confirm"
        if sel == 0 or sel == "n" or sel == "N":
            quit()
        elif sel == "y" or sel == "Y" or no_confirm == True:
            try:
                for i in packages_new:
                    print(f":> Uninstalling \"{i}\", please wait.")
                    rmtree(f"{libraries_root}{i}")
                    read_version_db = open(f"{libraries_root}.ver_db", "r")
                    ver_db_dict = loads(read_version_db.read())
                    ver_db_dict.pop(i)
                    read_version_db.close()
                    version_db = open(f"{libraries_root}.ver_db", "w")
                    version_db.write(dumps(ver_db_dict))
                    version_db.close()
            except PermissionError:
                print(f"Error: Failed to uninstall package \"{i['id']}\", no permission.")
                exit()
        else:
            quit()

if argv[1] == "update":
    if path.isfile(f"{libraries_root}.ver_db") == False:
        init_ver_db = open(f"{libraries_root}.ver_db", "w")
        init_ver_db.write(dumps({"base": "base"}))
        init_ver_db.close()
    read_version_db = open(f"{libraries_root}.ver_db", "r")
    ver_db_dict = loads(read_version_db.read())
    read_version_db.close()
    update_db = []
    update_ls = []
    for i in ver_db_dict:
        if i == "base":
            pass
        else:
            res = requests.get(f"{base_url}{i}")
            if res.status_code == 200:
                build = loads(res.text)
                if i in update_db:
                    pass
                else:
                    if build["version"] != ver_db_dict[i]:
                        update_db.append(build["id"])
                        update_ls.append(f"{i} {ver_db_dict[i]} -> {build['version']}")
            else:
                print(f"Error: Package \"{i}\" not found.")
                quit()
    if len(update_db) != 0:
        print(f":: Package(s) to be updated:")
        print("\n".join(update_ls)+"\n\n:: Proceed? [Y/n]")
        if no_confirm == False:
            sel = input(">>> ")
        else:
            sel = "no_confirm"
        if len(sel) == 0 or sel == "y" or sel == "Y" or no_confirm == True:
            print(":> Updating packages, please wait.")
            getoutput(f"{executable} {argv[0]} install {' '.join(update_db)} --no-confirm")
    else:
        print("Error: No updates available.")

if argv[1] == "publish":
    print("Error: Not implemented yet.")
    quit()

if argv[1] == "unpublish":
    print("Error: Not implemented yet.")
    quit()