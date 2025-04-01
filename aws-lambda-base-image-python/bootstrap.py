"""
Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
"""

import json
import logging
import os
import site
import sys
import time
import traceback
import warnings
import awslambdaric.__main__ as awslambdaricmain


def is_pythonpath_set():
    return "PYTHONPATH" in os.environ


def get_opt_site_packages_directory():
    return '/opt/python/lib/python{}.{}/site-packages'.format(sys.version_info.major, sys.version_info.minor)

def get_var_lang_site_package_directory():
    return '/var/lang/lib/python{}.{}/site-packages'.format(sys.version_info.major, sys.version_info.minor)

def get_opt_python_directory():
    return '/opt/python'


# set default sys.path for discoverability
# precedence: LAMBDA_TASK_ROOT -> /opt/python/lib/pythonN.N/site-packages -> /opt/python
def set_default_sys_path():
    if not is_pythonpath_set():
        sys.path.insert(0, get_var_lang_site_package_directory())
        sys.path.insert(0, get_opt_python_directory())
        sys.path.insert(0, get_opt_site_packages_directory())
#     'LAMBDA_TASK_ROOT' is function author's working directory
#     we add it first in order to mimic the default behavior of populating sys.path and make modules under 'LAMBDA_TASK_ROOT'
#     discoverable - https://docs.python.org/3/library/sys.html#sys.path
    sys.path.insert(0, os.environ['LAMBDA_TASK_ROOT'])


def add_default_site_directories():
#     Set 'LAMBDA_TASK_ROOT as site directory so that we are able to load all customer .pth files
    site.addsitedir(os.environ["LAMBDA_TASK_ROOT"])
    if not is_pythonpath_set():
        site.addsitedir(get_opt_site_packages_directory())
        site.addsitedir(get_opt_python_directory())

def set_default_pythonpath():
    if not is_pythonpath_set():
#         keep consistent with documentation: https://docs.aws.amazon.com/lambda/latest/dg/lambda-environment-variables.html
        os.environ["PYTHONPATH"] = os.environ["LAMBDA_RUNTIME_DIR"]


def main():
    set_default_sys_path()
    add_default_site_directories()
    set_default_pythonpath()
    awslambdaricmain.main([os.environ["LAMBDA_TASK_ROOT"], os.environ["_HANDLER"]])

if __name__ == '__main__':
    main()
