import ../common

## TYPES
type
    FileProperties* = enum
        ## As defined in stat command
        AccessRightsOctal = "%a"
        AccessRightsHuman = "%A"
        AllocatedBlocksCount = "%b"
        BlockSize = "%B"
        SelinuxContext = "%C"
        DeviceNumberDecimal = "%d"
        DeviceNumberHex = "%D"     
        RawModeHex = "%f"     
        FileTypeRaw = "%F"     
        GroupOwnerId = "%g"
        GroupOwnerName = "%G"
        HardLinksCount = "%h"
        InodeNumber = "%i"
        MountPoint = "%m"     
        FileName = "%n"
        FileNameQuotedWithDereferenceIfSymbolicLink = "%N"     
        OptimalIOTransferSizeHint = "%o"     
        TotalSize = "%s"
        MajorDeviceHex = "%t"     
        MinorDeviceHex = "%T"
        UserOwnerId = "%u"
        UserOwnerName = "%U"
        TimeOfBirthHuman = "%w"
        TimeOfBirthEpoch = "%W"
        TimeOfLastAccessHuman = "%x"
        TimeOfLastAccessEpoch = "%X"
        TimeofLastModificationHuman = "%y"
        TimeofLastModificationEpoch = "%Y"
        TimeofLastStatusChangeHuman = "%z"
        TimeofLastStatusChangeEpoch = "%Z"

    FileType* = enum
        File = "regular file"
        Directory = "directory"
        SymLink = "symbolic link"
        Char = "character special file"
        NamedPipe = "fifo"
        Block = "block special device"
        Socket = "socket"

    BlockDevInfo* = enum
        # Using blkid
        Uuid = "UUID", PartUuid = "PARTUUID",
        Label = "LABEL", FsType = "TYPE",
        # Using blockdev
        Size = "--getsize64", NumberOf512Sectors = "--getsz"
        KernelBlockSize = "--getbsz"
        

proc getFileProperty*(sh: ProcArgs, path: Path, property: FileProperties): Future[string] =
    sh.runGetOutput(@["stat", "-c", $property, $path], internalCmd.merge(
        envModifier = some {"LANG": "US"}.toTable())
    )

proc getFileProperty*(sh: ProcArgs, path: Path, property: openArray[FileProperties]): Future[seq[string]] =
    let propertyStr = property.join("\n")
    sh.runGetLines(@["stat", "-c", propertyStr, $path], internalCmd.merge(
        envModifier = some {"LANG": "US"}.toTable())
    )

proc getFileType*(sh: ProcArgs, path: Path): Future[FileType] {.async.} =
    let rawtype = await sh.getFileProperty(path, FileTypeRaw)
    for Type in FileType:
        if rawtype == $Type:
            return Type
    raise newException(OSError, "FileType undetermined")

proc getBlockDevInfo*(sh: ProcArgs, path: Path, property: BlockDevInfo): Future[string] =
    if property in { Size, NumberOf512Sectors, KernelBlockSize }:
        sh.runGetOutput(@["blockdev", $property, $path])
    else:
        sh.runGetOutput(@["blkid", "-o", "value", "-s", $property,$path])

proc isMountPoint*(sh: ProcArgs, path: Path): Future[bool] =
    sh.runCheck(@["mountpoint", "-q", $path], internalCmd)

proc findMntSource*(sh: ProcArgs, path: Path): Future[Path] =
    sh.runGetOutput(@["findmnt", "--noheadings", "--first-only", "-o", "SOURCE",$path])

## OWNER AND GROUPS
proc chmod*(sh: ProcArgs, path: Path, octal_mode: string): Future[void] =
    sh.runAssertDiscard(@["chmod", octal_mode, $path], internalCmd)

proc chown*(sh: ProcArgs, path: Path, user: string, group: string = ""): Future[void] =
    sh.runAssertDiscard(@["chown",
        (if group != "":
            user & ":" & group
        else:
            user),
        $path
    ], internalCmd)