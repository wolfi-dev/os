#!/usr/bin/env python
import os
import shlex
import sys

# Entrypoint is start.sh
command = ["jupyter-lab"]

# set default ip to 0.0.0.0
if "--ip=" not in os.environ.get("NOTEBOOK_ARGS", ""):
    command.append("--ip=0.0.0.0")

if "NOTEBOOK_ARGS" in os.environ:
    command += shlex.split(os.environ["NOTEBOOK_ARGS"])

command += sys.argv[1:]
print("Executing: " + " ".join(command))
os.execvp(command[0], command)

