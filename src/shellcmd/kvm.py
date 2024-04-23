#!/usr/bin/python3

from subprocess import run

PROPERTIES = { "dependencies": [ "qemu-kvm", "qemu-system", "cpu-checker", "bridge-utils",
    "virt-manager", "virtinst", "libvirt-daemon", "libvirt-daemon-system", "libvirt-clients", "libguestfs-tools", "libosinfo-bin" ] }

def isVirtualizationPossible():
    run(["kvm-ok"])

def setup():
    modprobe vhost_net

