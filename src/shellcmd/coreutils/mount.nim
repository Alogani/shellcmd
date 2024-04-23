import ./mkfs
import ./[common]

export mkfs

type
    MountFlag* = enum
        Remount = "remount",
        Defaults = "defaults", NoFail = "nofail",
        AsyncIO = "async", NoAsyncIO = "sync"
        UpdateFileAccessTime = "atime", NoUpdateFileAccessTime = "noatime"
        NoMoutableByOrdinaryUser = "nouser", MountableByOrdinaryUser = "user", MountableByAll = "users"
        ReadWrite = "rw", ReadOnly = "ro"
        InterpretBlockDevice = "dev", NoInterpretBlockDevice = "nodev",
        AutoMount = "auto", NoAutoMount = "noauto",
        AllowBinaryExec = "exec", NoAllowBinaryExec = "noexec",
        AllowSuid = "suid", NoAllowSuid = "nosuid",

    DeviceID* = object
        value*: string
        deviceType*: DeviceType

    DeviceType* = enum
        Uuid, PartUuid, FilePath

const
    DefaultMountFlags* = { ReadWrite, AllowSuid, InterpretBlockDevice,
        AllowBinaryExec, AutoMount, NoMoutableByOrdinaryUser, AsyncIO }

    Auto = FileSystemType()


converter toDeviceId*(path: Path): DeviceId =
    DeviceID(value: $path, deviceType: FilePath)


func getMountRepr(dev: DeviceID): string
func toString*(flags: set[MountFlag]): string


proc mount*(sh: ProcArgs, path, dest: Path, mountFlags: set[MountFlag] = {}, bindMount = false, fsType = Auto, otherOptions = ""): Future[void] =
    sh.runAssertDiscard(@["mount"] &
        (if fsType != Auto: @["-t", fsType.typeRepr] else: @[]) &
        (if mountFlags != {} or otherOptions != "": @["-o", @[mountFlags.toString(), otherOptions].join(",")] else: @[]) &
        (if bindMount: @["--bind"] else: @[]) &
        @[$path, $dest],
    internalCmd)

proc mount*(sh: ProcArgs, dev: DeviceID, dest: Path, mountFlags: set[MountFlag] = {}, fsType: FileSystemType, otherOptions = ""): Future[void] =
    sh.mount(dev.getMountRepr(), dest, fsType = fsType, mountFlags = mountFlags, otherOptions = otherOptions)

proc mount*(sh: ProcArgs, dest: Path, mountFlags: set[MountFlag] = {}, fsType: FileSystemType = Auto, otherOptions = ""): Future[void] =
    sh.runAssertDiscard(@["mount", "-t", fsType.typeRepr] &
        (if fsType != Auto: @["-t", fsType.typeRepr] else: @[]) &
        (if mountFlags != {}: @["-o", @[mountFlags.toString(), otherOptions].join(",")] else: @[]) &
        @[$dest],
    internalCmd)

proc umount*(sh: ProcArgs, path: Path) {.async.} =
    await sh.runAssertDiscard(@["umount", path], internalCmd)

proc mountAll*(sh: ProcArgs) {.async.} =
    await sh.runAssertDiscard(@["mount", "-a"], internalCmd)

proc listMounts*(sh: ProcArgs): Future[seq[string]] {.async.} =
    collect:
        for idx, line in await(sh.runGetLines(@["findmnt", "-l"], internalCmd)).pairs():
            if idx == 0:
                continue
            let data = line.split(" ")[0]
            if data != "":
                data

func toString*(flags: set[MountFlag]): string =
    if flags == DefaultMountFlags:
        result = $Defaults
    else:
        for opt in flags:
            result.add $opt
            result.add ","
        result.removeSuffix(",")

func getMountRepr(dev: DeviceID): string =
    case dev.devicetype:
    of Uuid:
        "UUID=" & dev.value
    of PartUuid:
        "PARTUUID=" & dev.value
    of FilePath:
        dev.value