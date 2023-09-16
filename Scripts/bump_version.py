from tempfile import mkstemp
from shutil import move
from os import fdopen, remove
import sys

def replace(file_path, new_url, new_sha):
    #Create temp file
    fh, abs_path = mkstemp()
    new_lines = []
    with open(file_path) as file:
        new_lines = file.readlines()

        new_lines[3] = "\turl \"%s\"\n" % (new_url) 
        new_lines[4] = "\tsha256 \"%s\"\n" % (new_sha)

    with open(file_path, 'w') as file:
        for line in new_lines:
            file.write("%s" % (line))


if len(sys.argv) == 3:
    replace("./homebrew-formulae/Formula/muter.rb", 
            "https://github.com/muter-mutation-testing/muter/archive/refs/tags/%s.zip" % (sys.argv[1]),
            sys.argv[2])

else:
    print("usage: bump_version new_version sha256_hash_of_new_version")