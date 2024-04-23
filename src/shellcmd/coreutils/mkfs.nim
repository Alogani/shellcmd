import ./[common]

type
    FileSystemType* = object
        typeRepr*: string
        mkfsCmd*: seq[string]

const
    Swap* = FileSystemType(typeRepr: "swap", mkfsCmd: @["mkswap"])
    Ext2* = FileSystemType(typeRepr: "ext2", mkfsCmd: @["mkfs", "-t", "ext2"])
    Ext3* = FileSystemType(typeRepr: "ext3", mkfsCmd: @["mkfs", "-t", "ext3"])
    Ext4* = FileSystemType(typeRepr: "ext4", mkfsCmd: @["mkfs", "-t", "ext3"])
    Ntfs* = FileSystemType(typeRepr: "ntfs", mkfsCmd: @["mkfs", "-t", "ntfs"])
    Fat32* = FileSystemType(typeRepr: "vfat", mkfsCmd: @["mkfs.vfat", "-F", "32"])
    Fat16* = FileSystemType(typeRepr: "vfat", mkfsCmd: @["mkfs.vfat", "-F", "16"])
    SysFS* = FileSystemType(typeRepr: "sysfs", mkfsCmd: @[])
    ProcFS* = FileSystemType(typeRepr: "proc", mkfsCmd: @[])
    DevFs* = FileSystemType(typeRepr: "devtmpfs", mkfsCmd: @[])
    DevPtsFs* = FileSystemType(typeRepr: "devpts", mkfsCmd: @[])


proc mkfs*(sh: ProcArgs, path: Path, fsType: FileSystemType): Future[void] =
    if fsType.mkfsCmd.len == 0:
        raise newException(OsError, "FileSystem type is not valid for mkfs")
    sh.runAssertDiscard(fsType.mkfsCmd & @[$path], internalCmd)

proc mke2fs*(sh: ProcArgs, path: Path, fsType: FileSystemType, uuid = "", reservedBlockPercent = 5): Future[void] =
    ## Specialized version for ext2/ext3/ext4 filesystems, see man
    if fsType.typeRepr[0..2] != "ext":
        raise newException(OsError, "FileSystem type is not valid for mke2fs")
    sh.runAssertDiscard(fsType.mkfsCmd & @[$path] &
        (if uuid != "": @["-U", uuid] else: @[]) &
        (if reservedBlockPercent != 5: @["-m", $reservedBlockPercent] else: @[])
    , internalCmd)