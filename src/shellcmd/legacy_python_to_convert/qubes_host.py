#!/usr/bin/python3

from subprocess import run

def attach_device_persistently(vm_name: str, device_id: str):
    #Device id example: dom0:sdb1
    run(["qvm-block", "attach", "--persistent", vm_name, device_id])

def change_copypaste_shortcut():
    with open("/etc/qubes/guid.conf", "a") as file:
        file.writes(["### SCRIPTED CHANGE ### BEGIN",
            'secure_copy_sequence = "Mod4-c"',
            'secure_paste_sequence = "Mod4-v"',
            "### SCRIPTED CHANGE ### END"
