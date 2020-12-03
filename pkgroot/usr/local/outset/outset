#!/usr/local/outset/python3

"""
This script automatically processes packages, profiles, and/or scripts at
boot, on demand, and/or login.
"""

##############################################################################
# Copyright 2014-Present Joseph Chilcote
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may not
#  use this file except in compliance with the License. You may obtain a copy
#  of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
##############################################################################

from __future__ import absolute_import, division, print_function, unicode_literals

import argparse
import datetime
import logging
import os
import platform
import plistlib
import pwd
import shutil
import subprocess
import sys
import time
import warnings
from distutils.version import StrictVersion as version
from platform import mac_ver
from stat import S_IWOTH, S_IXOTH

__author__ = "Joseph Chilcote (chilcote@gmail.com)"
__version__ = "3.0.3"

if not sys.warnoptions:
    warnings.simplefilter("ignore")

outset_dir = "/usr/local/outset"
boot_every_dir = os.path.join(outset_dir, "boot-every")
boot_once_dir = os.path.join(outset_dir, "boot-once")
login_every_dir = os.path.join(outset_dir, "login-every")
login_once_dir = os.path.join(outset_dir, "login-once")
login_privileged_every_dir = os.path.join(outset_dir, "login-privileged-every")
login_privileged_once_dir = os.path.join(outset_dir, "login-privileged-once")
on_demand_dir = os.path.join(outset_dir, "on-demand")
share_dir = os.path.join(outset_dir, "share")
outset_preferences = os.path.join(share_dir, "com.chilcote.outset.plist")
on_demand_trigger = "/private/tmp/.com.github.outset.ondemand.launchd"
login_privileged_trigger = "/private/tmp/.com.github.outset.login-privileged.launchd"
cleanup_trigger = "/private/tmp/.com.github.outset.cleanup.launchd"

if os.geteuid() == 0:
    log_file = "/var/log/outset.log"
    console_uid = os.stat('/dev/console').st_uid
    run_once_plist = os.path.join(
        "/usr/local/outset/share",
        "com.github.outset.once." + str(console_uid) + ".plist",
    )
else:
    if not os.path.exists(os.path.expanduser("~/Library/Logs")):
        os.makedirs(os.path.expanduser("~/Library/Logs"))
    log_file = os.path.expanduser("~/Library/Logs/outset.log")
    run_once_plist = os.path.expanduser(
        "~/Library/Preferences/com.github.outset.once.plist"
    )

logging.basicConfig(
    format="%(asctime)s - %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
    level=logging.DEBUG,
    filename=log_file,
)
stdout_logging = logging.StreamHandler()
stdout_logging.setFormatter(logging.Formatter())
logging.getLogger().addHandler(stdout_logging)


def network_up():
    """Returns True if network interfaces are none of localhost or 0.0.0.0"""
    cmd = ["/sbin/ifconfig", "-a", "inet"]
    out = subprocess.check_output(cmd).decode("utf-8")
    for line in out.splitlines():
        if "inet" in line:
            address = line.split()[1]
            if not address in ["127.0.0.1", "0.0.0.0"]:
                return True
    return False


def wait_for_network(timeout):
    """Waits for a valid IP before continuing"""
    for x in range(timeout):
        if network_up():
            return True
        else:
            logging.info("Waiting for network")
            time.sleep(10)


def disable_loginwindow():
    """Disables the loginwindow process"""
    logging.info("Disabling loginwindow process")
    cmd = [
        "/bin/launchctl",
        "unload",
        "/System/Library/LaunchDaemons/com.apple.loginwindow.plist",
    ]
    subprocess.call(cmd)


def enable_loginwindow():
    """Enables the loginwindow process"""
    logging.info("Enabling loginwindow process")
    cmd = [
        "/bin/launchctl",
        "load",
        "/System/Library/LaunchDaemons/com.apple.loginwindow.plist",
    ]
    subprocess.call(cmd)


def get_hardwaremodel():
    """Returns the hardware model of the Mac"""
    cmd = ["/usr/sbin/sysctl", "-n", "hw.model"]
    return subprocess.check_output(cmd).decode('utf-8').strip()


def get_serialnumber():
    """Returns the serial number of the Mac"""
    out = subprocess.check_output(
        ["/usr/sbin/ioreg", "-c", "IOPlatformExpertDevice"]
    ).decode('utf-8')
    serial_line = [x for x in out.splitlines() if "IOPlatformSerialNumber" in x][0]
    return serial_line.split()[-1].strip('"')


def get_buildversion():
    """Returns the os build version of the Mac"""
    cmd = ["/usr/sbin/sysctl", "-n", "kern.osversion"]
    return subprocess.check_output(cmd).decode('utf-8').strip()


def get_osversion():
    """Returns macOS version, may be inconsistent depending on interpreter used"""
    return platform.mac_ver()[0]


def sys_report():
    """Logs system information to log file"""
    logging.debug("Model: %s", get_hardwaremodel())
    logging.debug("Serial: %s", get_serialnumber())
    logging.debug("OS: %s", get_osversion())
    logging.debug("Build: %s", get_buildversion())


def cleanup(pathname):
    """Deletes given script"""
    try:
        os.remove(pathname)
    except:
        shutil.rmtree(pathname)


def mount_dmg(dmg):
    """Attaches dmg"""
    dmg_path = os.path.join(dmg)
    cmd = [
        "/usr/bin/hdiutil",
        "attach",
        "-nobrowse",
        "-noverify",
        "-noautoopen",
        dmg_path,
    ]
    logging.info("Attaching %s", dmg_path)
    out = subprocess.check_output(cmd).decode('utf-8')
    return out.split("\n")[-2].split("\t")[-1]


def detach_dmg(dmg_mount):
    """Detaches dmg"""
    logging.info("Detaching %s", dmg_mount)
    cmd = ["/usr/bin/hdiutil", "detach", "-force", dmg_mount]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (_, err) = proc.communicate()
    if err:
        logging.error("Unable to detach %s: %s", dmg_mount, err.decode('utf-8'))


def check_perms(pathname):
    mode = os.stat(pathname).st_mode
    owner = os.stat(pathname).st_uid
    if pathname.lower().endswith(("pkg", "mpkg", "dmg", "mobileconfig")):
        if owner == 0 and not (mode & S_IWOTH):
            return True
    else:
        if owner == 0 and (mode & S_IXOTH) and not (mode & S_IWOTH):
            return True
    return False


def install_package(pkg):
    """Installs pkg onto boot drive"""
    if pkg.lower().endswith("dmg"):
        dmg_mount = mount_dmg(pkg)
        for f in os.listdir(dmg_mount):
            if f.lower().endswith(("pkg", "mpkg")):
                pkg_to_install = os.path.join(dmg_mount, f)
    elif pkg.lower().endswith(("pkg", "mpkg")):
        dmg_mount = False
        pkg_to_install = pkg
    logging.info("Installing %s", pkg_to_install)
    cmd = ["/usr/sbin/installer", "-pkg", pkg_to_install, "-target", "/"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (_, err) = proc.communicate()
    if err:
        logging.info("Failure installing %s: %s", pkg_to_install, err.decode('utf-8'))
        return False
    if dmg_mount:
        time.sleep(5)
        detach_dmg(dmg_mount)
    return True


def install_profile(pathname):
    """Install mobileconfig located at given pathname"""
    # profiles has new verbs in 10.13.
    if version(mac_ver()[0]) >= version("10.13"):
        cmd = ["/usr/bin/profiles", "install", "-path=%s" % pathname]
    else:
        cmd = ["/usr/bin/profiles", "-IF", pathname]

    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info("Installing profile %s", pathname)
        (_, err) = proc.communicate()
        if err:
            logging.error("Failure processing %s: %s", pathname, err.decode('utf-8'))
            return False
    except OSError as err:
        logging.error("Failure processing %s: %s", pathname, err.decode('utf-8'))
        return False
    return True


def run_script(pathname):
    """Runs script located at given pathname"""
    logging.info("Processing %s", pathname)
    # first attempt, mostly via https://stackoverflow.com/a/4760517
    try:
        result = subprocess.run(
            pathname, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        if result.stderr and result.returncode == 0:
            logging.info(
                "Output from %s on stderr but it still ran successfully: %s",
                pathname,
                result.stderr.decode('utf-8'),
            )
        elif result.returncode > 0:
            logging.error("Failure processing %s: %s", pathname, result.stderr.decode('utf-8'))
            return False
    except OSError as err:
        logging.error("Failure processing %s: %s", pathname, err.decode('utf-8'))
        return False
    return True


def process_items(path, delete_items=False, once=False, override={}):
    """Processes scripts/packages to run"""

    if not os.path.exists(path):
        logging.error("%s does not exist. Exiting", path)
        exit(1)

    items_to_process = []
    packages = []
    scripts = []
    profiles = []
    d = {}

    for dirpath, _, files in os.walk(path):
        items_to_process.extend(os.path.join(dirpath, f) for f in files)

    items_to_process = sorted(
        items_to_process,
        key=lambda file: (os.path.dirname(file), os.path.basename(file)),
    )

    for pathname in items_to_process:
        if check_perms(pathname):
            if pathname.lower().endswith(("pkg", "mpkg", "dmg")):
                packages.append(pathname)
            elif pathname.lower().endswith("mobileconfig"):
                profiles.append(pathname)
            else:
                scripts.append(pathname)
        else:
            logging.error("Bad permissions: %s", pathname)

    if once:
        try:
            with open(run_once_plist, 'rb') as fp:
                d = plistlib.load(fp)
        except:
            d = {}

    for package in packages:
        if once:
            if package not in d:
                if install_package(package):
                    d[package] = datetime.datetime.now()
            else:
                if package in override:
                    if override[package] > d[package]:
                        if install_package(package):
                            d[package] = datetime.datetime.now()
        else:
            install_package(package)
        if delete_items:
            cleanup(package)

    for profile in profiles:
        if once:
            if profile not in d:
                if install_profile(profile):
                    d[profile] = datetime.datetime.now()
            else:
                if profile in override:
                    if override[profile] > d[profile]:
                        if install_profile(profile):
                            d[profile] = datetime.datetime.now()
        else:
            install_profile(profile)
        if delete_items:
            cleanup(profile)

    for script in scripts:
        if once:
            if script not in d:
                if run_script(script):
                    d[script] = datetime.datetime.now()
            else:
                if script in override:
                    if override[script] > d[script]:
                        if run_script(script):
                            d[script] = datetime.datetime.now()
        else:
            run_script(script)
        if delete_items:
            cleanup(script)

    if d:
        with open(run_once_plist, 'wb') as fp:
            plistlib.dump(d, fp)

def main():
    """Main method"""

    parser = argparse.ArgumentParser(
        description="This script automatically \
            processes packages, profiles, and/or scripts at boot, on demand,\
            and/or login."
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--boot", action="store_true", help="Used by launchd for scheduled runs at boot"
    )
    group.add_argument(
        "--login",
        action="store_true",
        help="Used by launchd for scheduled runs at login",
    )
    group.add_argument(
        "--login-privileged",
        action="store_true",
        help="Used by launchd for scheduled privileged runs at login",
    )
    group.add_argument(
        "--on-demand", action="store_true", help="Process scripts on demand"
    )
    group.add_argument(
        "--login-every",
        action="store_true",
        help="Manually process scripts in login-every",
    )
    group.add_argument(
        "--login-once",
        action="store_true",
        help="Manually process scripts in login-once",
    )
    group.add_argument(
        "--cleanup",
        action="store_true",
        help="Used by launchd to clean up on-demand dir",
    )
    group.add_argument("--version", action="store_true", help="Show version number")
    group.add_argument(
        "--add-ignored-user",
        action="append",
        metavar="username",
        help="Add user to ignored list",
    )
    group.add_argument(
        "--remove-ignored-user",
        action="append",
        metavar="username",
        help="Remove user from ignored list",
    )
    group.add_argument(
        "--add-override",
        action="append",
        metavar="scripts",
        help="Add scripts to override list",
    )
    group.add_argument(
        "--remove-override",
        action="append",
        metavar="scripts",
        help="Remove scripts from override list",
    )
    args = parser.parse_args()

    loginwindow = True
    console_user = pwd.getpwuid(os.getuid())[0]
    network_wait = True
    network_timeout = 180
    ignored_users = []
    override_login_once = {}
    continue_firstboot = True
    prefs = {}

    if os.path.exists(outset_preferences):
        with open(outset_preferences, 'rb') as fp:
            prefs = plistlib.load(fp)
        network_wait = prefs.get("wait_for_network", True)
        network_timeout = prefs.get("network_timeout", 180)
        ignored_users = prefs.get("ignored_users", [])
        override_login_once = prefs.get("override_login_once", {})

    if args.boot:
        working_directories = [
            boot_every_dir,
            boot_once_dir,
            login_every_dir,
            login_once_dir,
            login_privileged_every_dir,
            login_privileged_once_dir,
            on_demand_dir,
            share_dir,
        ]

        for directory in working_directories:
            if not os.path.exists(directory):
                logging.info("%s does not exist, creating now.", directory)
                os.makedirs(directory)

        if os.listdir(boot_once_dir):
            if network_wait:
                loginwindow = False
                disable_loginwindow()
                continue_firstboot = (
                    True if wait_for_network(timeout=network_timeout // 10) else False
                )
            if continue_firstboot:
                sys_report()
                process_items(boot_once_dir, delete_items=True)
            else:
                logging.error(
                    "Unable to connect to network. Skipping boot-once scripts..."
                )
            if not loginwindow:
                enable_loginwindow()
        if os.listdir(boot_every_dir):
            process_items(boot_every_dir)

        if not os.path.exists(outset_preferences):
            logging.info("Initiating preference file: %s" % outset_preferences)
            prefs["wait_for_network"] = network_wait
            prefs["network_timeout"] = network_timeout
            prefs["ignored_users"] = ignored_users
            prefs["override_login_once"] = override_login_once
            with open(outset_preferences, 'wb') as fp:
                plistlib.dump(prefs, fp)

        logging.info("Boot processing complete")

    if args.login:
        if console_user not in ignored_users:
            if os.listdir(login_once_dir):
                process_items(login_once_dir, once=True, override=override_login_once)
            if os.listdir(login_every_dir):
                process_items(login_every_dir)
            if os.listdir(login_privileged_once_dir) or os.listdir(
                login_privileged_every_dir
            ):
                open(login_privileged_trigger, "a").close()
        else:
            logging.info("Skipping login scripts for user %s", console_user)

    if args.login_privileged:
        if os.path.exists(login_privileged_trigger):
            cleanup(login_privileged_trigger)

        if console_user not in ignored_users:
            if os.listdir(login_privileged_once_dir):
                process_items(
                    login_privileged_once_dir, once=True, override=override_login_once
                )
            if os.listdir(login_privileged_every_dir):
                process_items(login_privileged_every_dir)
        else:
            logging.info("Skipping login scripts for user %s", console_user)

    if args.on_demand:
        if os.listdir(on_demand_dir):
            if console_user not in ("root", "loginwindow"):
                current_user = os.environ["USER"]
                if console_user == current_user:
                    process_items(on_demand_dir)
                else:
                    logging.info(
                        "User %s is not the current console user. Skipping on-demand run.",
                        current_user,
                    )
            else:
                logging.info("No current user session. Skipping on-demand run.")
        open(cleanup_trigger, "w").close()
        time.sleep(0.5)
        if os.path.exists(cleanup_trigger):
            cleanup(cleanup_trigger)

    if args.login_every:
        if console_user not in ignored_users:
            if os.listdir(login_every_dir):
                process_items(login_every_dir)

    if args.login_once:
        if console_user not in ignored_users:
            if os.listdir(login_once_dir):
                process_items(login_once_dir, once=True)

    if args.cleanup:
        logging.info("Cleaning up on-demand directory.")
        if os.path.exists(on_demand_trigger):
            cleanup(on_demand_trigger)
        if os.listdir(on_demand_dir):
            for f in os.listdir(on_demand_dir):
                cleanup(os.path.join(on_demand_dir, f))
        time.sleep(5)

    if args.add_ignored_user:
        if os.getuid() != 0:
            logging.error("Must be root to add users to ignored_users")
            exit(1)

        if not os.path.exists(share_dir):
            logging.info("%s does not exist, creating now.", share_dir)
            os.makedirs(share_dir)

        users_to_add = [i for i in args.add_ignored_user if i != ""]
        if users_to_add:
            users_to_add.extend(ignored_users)
            users_to_ignore = list(set(users_to_add)) if users_to_add else None
            if users_to_ignore:
                prefs["ignored_users"] = users_to_ignore
                with open(outset_preferences, 'wb') as fp:
                    plistlib.dump(prefs, fp)

    if args.remove_ignored_user:
        if os.getuid() != 0:
            logging.error("Must be root to remove users from ignored_users")
            exit(1)

        users_to_remove = args.remove_ignored_user
        if prefs.get("ignored_users"):
            for user in users_to_remove:
                if user in prefs["ignored_users"]:
                    prefs["ignored_users"].remove(user)
            with open(outset_preferences, 'wb') as fp:
                plistlib.dump(prefs, fp)

    if args.add_override:
        if os.getuid() != 0:
            logging.error("Must be root to add scripts to override_login_once")
            exit(1)

        if not os.path.exists(share_dir):
            logging.info("%s does not exist, creating now.", share_dir)
            os.makedirs(share_dir)

        overrides_to_add = [i for i in args.add_override if i != ""]
        if overrides_to_add:
            override_items = {}
            for override in overrides_to_add:
                override = os.path.join(login_once_dir, override)
                override_items[override] = datetime.datetime.now()
            if "override_login_once" in prefs.keys():
                prefs["override_login_once"].update(override_items)
            else:
                prefs["override_login_once"] = override_items
            with open(outset_preferences, 'wb') as fp:
                plistlib.dump(prefs, fp)

    if args.remove_override:
        if os.getuid() != 0:
            logging.error("Must be root to remove scripts from override_login_once")
            exit(1)

        scripts_to_remove = args.remove_override
        if prefs.get("override_login_once"):
            for script in scripts_to_remove:
                script = os.path.join(login_once_dir, script)
                if script in prefs["override_login_once"]:
                    del prefs["override_login_once"][script]
            with open(outset_preferences, 'wb') as fp:
                plistlib.dump(prefs, fp)

    if args.version:
        print(__version__)


if __name__ == "__main__":
    main()
