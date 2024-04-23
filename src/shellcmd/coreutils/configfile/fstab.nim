import ../file/[filecontent, filemanagement]
import ../[common, mkfs]
import ../mount {.all.}
import ./backupfile

export mount, mkfs

const FstabPath = Path("/dev/fstab")

type
    FsckOrder* = enum
        RootPartition, OtherPartition, Never


func toFstab(order: FsckOrder): string


proc addEntry*(sh: ProcArgs, device: DeviceID, mountDir: string, fsType: FileSystemType,
        mountflags: set[MountFlag], order: FsckOrder) {.async.} =
    let NewEntry = @[
        device.getMountRepr(),
        mountDir,
        fsType.typeRepr,
        mountflags.toString(),
        order.toFstab()
    ]
    await sh.backupFile(FstabPath)
    await sh.writeFile(FstabPath, NewEntry.join("\t"), append = true)

proc removeEntry*(sh: ProcArgs, device: DeviceID): Future[bool] {.async.} =
    var content = await sh.readLines(FstabPath)
    let devId = device.getMountRepr()
    var indexMatch = -1
    for idx, line in content.pairs():
        if line.startsWith(devId):
            indexMatch = idx
            break
    if indexMatch == -1:
        return false
    else:
        await sh.cp(FstabPath, $FstabPath & ".back", overwrite = true)
        content.delete(indexMatch)
        await sh.backupFile(FstabPath)
        await sh.writeLines(FstabPath, content)


func toFstab(order: FsckOrder): string =
    case order:
    of RootPartition:
        "1"
    of OtherPartition:
        "2"
    of Never:
        "0"