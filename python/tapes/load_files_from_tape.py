#!/root/utilities/cresis-toolbox/python/tapes/.venv/bin/python
"""
Automatically load tapes in the Qualstar Q40 and pull the files from the given list.

TAPES_FILE should point to a file produced by run_get_raw_files.m and map files
to tapes.

Author: Reece Mathews
"""
from subprocess import check_output
import subprocess
from collections import defaultdict, namedtuple
from contextlib import contextmanager
from pathlib import Path
import re
import os
import shutil
import tarfile
import time
from getpass import getpass

TAPES_FILE = '/root/utilities/tapes_harry_frames2.txt'  # Produced from run_get_raw_files.m
TAPE_LIB_DEV = "/dev/sg9"
TAPE_MOUNT_PATH = "/mnt/ltfs"
RESFS_TAPE_LIST = "resfs_tapes.txt"

# Determine with `lsscsi -g`
TAPE_DRIVE_DEVS = {
    "0": "/dev/sg8",
    "1": "/dev/sg7",
}
SKIP_EXISTING = True  # Do not ask to overwrite existing files and just skip instead
FS_PATH_SUBS = {  # Path subsitutions for destinations on the filesystem
   "/N/dc2/projects/cresis/": "/cresis/snfs1/data/Accum_Data/",
   "/N/dcwan/projects/cresis/": "/cresis/snfs1/data/Accum_Data/",
}

SSH_SERVER = "dtn.ku.edu"
SSH_PORT = 22


def removeprefix(string, prefix):
    """Reimplementing the Python 3.9 method for removing a string prefix."""
    return string[len(prefix):] if string.startswith(prefix) else string

def removesuffix(string, suffix):
    """Reimplementing the Python 3.9 method for removing a string suffix."""
    return string[:-len(suffix)] if string.endswith(suffix) else string


def get_tape_num(tape):
    """Retrieve the number from the tape label."""
    return int(removesuffix(removeprefix(tape, "OIB"), "L8"))


def parse_tapes_file():
    """Read the tapes file into a dict."""
    tape_mapping = defaultdict(list)
    path_mapping = {}
    all_files = set()

    with open(TAPES_FILE) as f:
        season = None
        for line in f:
            if season is None:
                season = line
                continue
            if line.startswith("Filelist: "):
                continue
            if line.startswith("tapes filename stored_filename"):
                continue
            if line.strip() == "":
                season = None
                continue

            parts = line.split()
            tapes = parts[0].split(",")
            original_path = parts[1]
            tape_path = parts[2]

            path_mapping[tape_path] = original_path

            if tape_path in all_files:
                print("Ignoring duplicate file " + tape_path)
            all_files |= {tape_path}

            for tape in tapes:
                tape_num = get_tape_num(tape)

                if tape_num % 2 == 0:  # We have even tapes
                    if tape_path not in tape_mapping[tape]:
                        tape_mapping[tape].append(tape_path)
                    break
            else:
                raise RuntimeError("No even tape for " + tape_path)

    if SKIP_EXISTING:
        # Remove existing files from list
        for tape, file_list in tape_mapping.items():

            files = []
            for file in file_list:
                # Keep files that don't exist or are 0 bytes
                file_path = Path(path_subs(path_mapping[file]))
                if not file_path.exists() or os.path.getsize(file_path) == 0:
                    files.append(file)
            tape_mapping[tape] = files

    return tape_mapping, path_mapping


def inventory():
    """Check the tape library's current inventory."""
    INV_RE_MATCH_INDICES = {
        "slot_type": 0,
        "slot_num": 1,
        "mailslot": 2,
        "full": 3,
        "original_slot_num": 6,
        "barcode": 7
    }
    # Hope someone else doesn't end up working on this 👍  - reece
    INV_RE_PATTERN = r"(Storage|Data Transfer) Element ([0-9]+)\s?(IMPORT\/EXPORT)?:(Full|Empty)( (\(Storage Element ([0-9]+) Loaded\))?:VolumeTag\s?=\s?(\w+))?"
    InvSlot = namedtuple("InvSlot", "slot_type slot_num mailslot full original_slot_num barcode")

    inv_output = check_output(["mtx", "-f", TAPE_LIB_DEV, "status"]).decode()
    inv_output = "\n".join(line.strip() for line in inv_output.split("\n"))
    matches = re.findall(INV_RE_PATTERN, inv_output)
    return [InvSlot(**{k: match[i] for k, i in INV_RE_MATCH_INDICES.items()}) for match in matches]


def load_tape(tape_barcode):
    """Load a tape into a drive"""
    inv = inventory()

    # Find tape
    slot = None
    for slot_ in inv:
        if slot_.barcode == tape_barcode:
            slot = slot_
            break
    else:
        raise RuntimeError("Tape not present: " + tape_barcode)

    if slot.slot_type == "Data Transfer":
        # tape already in drive
        print("Tape " + slot.barcode + " already loaded in drive " + slot.slot_num)
        return slot.slot_num

    # Find open drive
    drive_slot = None
    for slot_ in inv:
        if slot_.slot_type == "Data Transfer":
            drive_slot = slot_
            if slot_.full == "Empty":
                break
    else:
        # All drives full, unload last drive found
        if drive_slot is None:
            raise RuntimeError("No drives found")

        print("Unloading " + drive_slot.barcode + " from drive " + drive_slot.slot_num + " to slot " + drive_slot.original_slot_num)
        check_output(["mtx", "-f", TAPE_LIB_DEV, "unload", drive_slot.original_slot_num, drive_slot.slot_num])

    print("Loading " + slot.barcode + " from slot " + slot.slot_num + " to drive " + drive_slot.slot_num)
    check_output(["mtx", "-f", TAPE_LIB_DEV, "load", slot.slot_num, drive_slot.slot_num])

    return drive_slot.slot_num


def unmount_drive():
    """Unmount the TAPE_MOUNT_PATH."""
    if os.path.ismount(TAPE_MOUNT_PATH):
        print("Unmounting", TAPE_MOUNT_PATH)
        check_output(["umount", TAPE_MOUNT_PATH])


@contextmanager
def mount_drive(drive_num):
    """Mount the given drive with LTFS."""
    unmount_drive()
    drive_dev = TAPE_DRIVE_DEVS[drive_num]
    # TODO[reece]: Handle mount hanging forever
    print("Mounting " + drive_dev)
    subprocess.call(["ltfs", "-o", f"devname={drive_dev}", TAPE_MOUNT_PATH],
                     stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    if not os.listdir(TAPE_MOUNT_PATH):
        raise RuntimeError("Failed to mount " + drive_dev)
    try:
        yield
    finally:
        unmount_drive()


def path_subs(path):
    """Perform each path substitution on the given path."""
    for sub in FS_PATH_SUBS:
        path = path.replace(sub, FS_PATH_SUBS[sub])
    return path.replace('\\', '/')


def get_ssh_client():
    """Prompt the user for login details for the ssh server."""
    import paramiko
    from scp import SCPClient

    try:
        # See if we have a previous connection
        return get_ssh_client.scp_client

    except AttributeError:
        pass # No previous connection, make a new one

    while True:
        try:
            # See if credentials are still stored (as in when a timeout occurs)
            ssh_user = get_ssh_client.ssh_user
            ssh_password = get_ssh_client.ssh_password
        except AttributeError:
            # Ask for credentials instead
            ssh_user = input(f"Enter your SSH username for {SSH_SERVER}: ")
            ssh_password = getpass(f"Enter your SSH password for {SSH_SERVER}: ")

        # Create the client
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        get_ssh_client.ssh_client = ssh_client

        # Attempt to connect to the SSH Server
        print(f"Attempting to connect to scp server {SSH_SERVER}")
        try:
            ssh_client.connect(SSH_SERVER, port=SSH_PORT, username=ssh_user, password=ssh_password)
            get_ssh_client.ssh_user = ssh_user
            get_ssh_client.ssh_password = ssh_password
            break

        except paramiko.AuthenticationException:
            print("Username or password incorrect")

    scp_client = SCPClient(ssh_client.get_transport())
    get_ssh_client.scp_client = scp_client

    return scp_client


def scp_file_from_server(remote_file_path, fs_file_path, attempts=3):
    """Copy a file not on our tapes from the ssh server."""
    from scp import SCPException
    import paramiko

    scp_client = get_ssh_client()

    try:
        time.sleep(.1)
        scp_client.get(remote_path=remote_file_path, local_path=fs_file_path)
    except (SCPException, paramiko.buffered_pipe.PipeTimeout) as e:
        # Try connecting again if there is a timeout
        if attempts < 0:
            print(f"**Failed to copy {e.args} file from server: " + remote_file_path)
            return

        if type(e.args) is tuple and len(e.args) > 0 and "Permission denied" in e.args[0]:
            print(f"User does not have access permissions on file: {remote_file_path}")
            return

        print("Timeout during SCP, waiting and trying again")
        time.sleep(.5)
        get_ssh_client.scp_client.close()
        get_ssh_client.ssh_client.close()
        del get_ssh_client.scp_client  # Reset stored connection
        return scp_file_from_server(remote_file_path, fs_file_path, attempts=attempts-1)


def copy_file(file, path_mapping, attempts=1, remote=False):
    """Copy the given file to its original locations."""
    # Perform sanity checks on file and destination
    # fs = filesystem (destination) paths as opposed to tape (source) paths

    # Source checks
    if remote:
        remote_file_path = "/" + file.replace('\\', '/').lstrip('/')
        print(f"\nsource {SSH_SERVER}:{remote_file_path}")
    else:
        tape_file_path = Path(TAPE_MOUNT_PATH) / file.replace('\\', '/').lstrip('/')
        tape_file_exists = tape_file_path.exists()
        tape_file_size = os.path.getsize(tape_file_path) / 1024 ** 2 if tape_file_exists else None
        print("\nsource (exists:)", tape_file_exists, f"{tape_file_size if tape_file_size is not None else 0} MB", tape_file_path)

        if not tape_file_exists:
            if attempts > 0:
                print("Could not find source file on tape, waiting one second and retrying.")
                time.sleep(1)
                return copy_file(file, path_mapping, attempts=attempts-1, remote=remote)
            input("**Could not find source file on tape, perhaps try remounting. Press enter to skip.**")

    # Destination checks
    fs_file_path = Path(path_subs(path_mapping[file]))
    fs_file_exists = fs_file_path.exists()
    fs_file_size = os.path.getsize(fs_file_path) / 1024 ** 2 if fs_file_exists else None
    print("-> destination (exists:)", fs_file_exists, f"{fs_file_size if fs_file_size is not None else 0} MB", fs_file_path)

    # Check if destination already exists on filesystem
    if fs_file_exists and (fs_file_size is not None and fs_file_size > 0):
        if SKIP_EXISTING or input("**File already exists on file system**, skip (y) or halt (n)?") == "y":
            print("Already exists, skipping")
            return
        else:
            raise RuntimeError("File already exists on file system")

    # Check if parent folder path exists
    fs_parent_path = fs_file_path.parent
    if not fs_parent_path.exists():
        os.makedirs(fs_parent_path, exist_ok=True)

    # Perform copy
    if remote:
        scp_file_from_server(remote_file_path, fs_file_path)
    else:
        shutil.copy2(tape_file_path, fs_file_path)

    if fs_file_path.name.endswith("small_file_archive.tar"):
        os.chdir(fs_parent_path)
        with tarfile.open(fs_file_path) as tar:
            tar.extractall()
        if os.path.exists("delete_this_zero_file"):
            os.remove("delete_this_zero_file")

        os.remove(fs_file_path)

    os.chdir("/")


def load_tapes(tape_mapping, path_mapping, resfs_tapes):
    """Load each tape and retrieve the files back to their original location."""
    for tape in tape_mapping:

        if not tape_mapping[tape]:
            # Skip empty file sets
            print("Skipping tape with no files: " + tape)
            continue

        files = tape_mapping[tape]

        if tape in resfs_tapes:
            print("Tape in ResFS: " + tape, f"will attempt to retrieve from {SSH_SERVER}")
            for file in files:
                copy_file(file, path_mapping, remote=True)

            continue

        # Load files from tape
        try:
            drive_num = load_tape(tape)
        except RuntimeError:
            print("Skipping missing tape: " + tape)
            print("- Did not restore files:")
            for file in files:
                print("* ", TAPE_MOUNT_PATH + file, "->", path_subs(path_mapping[file]))
            continue

        with mount_drive(drive_num):
            for file in files:
                copy_file(file, path_mapping)


def read_resfs_tapes():
    """Read the list of tapes still in ResFS into a set."""
    with open(RESFS_TAPE_LIST) as f:
        return set(l.strip() for l in f.readlines())


if __name__ == "__main__":
    if os.geteuid() != 0:
        raise RuntimeError("Must be ran as root to access tape device")

    tape_mapping, path_mapping = parse_tapes_file()
    resfs_tapes = read_resfs_tapes()
    load_tapes(tape_mapping, path_mapping, resfs_tapes)

    print("Finished restoring files.")

    try:
        # Close scp connection if it was opened
        get_ssh_client.scp_client.close()

    except AttributeError:
        pass
