import sys
import os
import platform
from enum import Enum
import subprocess

class System(Enum):
	MACOS = 1
	LINUX = 2

def system() -> System:
	runningOS = platform.system().lower()
	if runningOS == "darwin":
		return System.MACOS
	else:
		return System.LINUX

binddir = "/usr/local/bin"
libdir = binddir + "/lib"
repodir = os.getcwd()
builddir = repodir + "/.build"

def build_release():
	build_command = ["swift", "build", "-c", "release", "--product", "muter"]

	if system() == System.MACOS:
		build_command.append("--disable-sandbox")

	subprocess.call(build_command)

def install():
	build_release()

	install_dir_command = ["install", "-d", binddir, libdir]
	install_command = ["install", builddir + "/release/muter", binddir]

	if system() == System.LINUX:
		sudo = ["sudo"]
		install_dir_command = sudo + install_dir_command
		install_command = sudo + install_command

	subprocess.call(install_dir_command)
	subprocess.call(install_command)


if len(sys.argv) == 2:
    if sys.argv[1] == "build_release":
    	build_release()
    elif sys.argv[1] == "install":
    	install()

else:
    print("usage: install_build build_release")
    print("usage: install_build install")