import ../coreutils
export coreutils
import ../private/dependencyhandler


DependencyPackages.linux.add("qemu-kvm")

type
    ImageFormat* = enum
        QCow2 = "qcow2", Raw = "raw"

proc toQemuString*(size: StorageSize): string =
    size.toString(suffix = "")