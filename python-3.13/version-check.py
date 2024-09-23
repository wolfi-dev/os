import sys

info = sys.version_info
found = "%s.%s.%s" % (info.major, info.minor, info.micro)

if len(sys.argv) > 1:
    expected = sys.argv[1]
    if found != expected:
        print("ERROR: expected version '%s' found '%s'" % (expected, found))
        sys.exit(1)

print("python version: " + found)
