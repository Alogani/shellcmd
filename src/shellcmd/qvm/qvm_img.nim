import ./private
export ImageFormat

type
    ResizeSign* = enum
        Grow, Shrink


proc createDisk*(sh: ProcArgs, path: Path, size: StorageSize, format: ImageFormat) {.async.} =
    await sh.unlink(path, nofail = true)
    await sh.runAssertDiscard(@[
        "qemu-img", "create", "-f", $format, path, size.toQemuString()
    ])
    
proc resize*(sh: ProcArgs, img: Path, sign: ResizeSign, sizeDiff: StorageSize, format: ImageFormat) {.async.} =
    ## shrink will create data loss at the end of disk
    if sign == Shrink:
        await sh.runAssertDiscard(@["qemu-img", "resize", "-f", $format, img, "--shrink", "-" & sizeDiff.toQemuString()])
    else:
        await sh.runAssertDiscard(@["qemu-img", "resize", "-f", $format, img, "+" & sizeDiff.toQemuString()])


proc attachPartitionsToHost*(sh: ProcArgs, img: Path, format: ImageFormat): Future[seq[Path]] {.async.} =
    ## Can then be mount with mount
    if format == Raw:
        return await losetup.attach(sh, img)
    else:
        let freeSlot = block:
            var res: char
            for file in await sh.find("/sys/class/block", @[matchName("nbd*")]):
                if "0\n" == await sh.readFile(file/"size"):
                    res = file.extractFileName()[3]
                    break
            res
        await sh.runAssertDiscard(@["modprobe", "nbd", "max_parts=16"], internalCmd)
        await sh.runAssertDiscard(@["qemu-nbd", "--connect=/dev/nbd" & freeSlot, img])
        await sh.find("/dev", @[matchName("nbd" & freeSlot & "*")])

proc detachPartitions*(sh: ProcArgs, rootPartition: Path) {.async.} =
    if rootPartition.extractFileName()[0 .. 2] == "nbd":
        await sh.runAssertDiscard(@["qemu-nbd", "-d", rootPartition])
    else:
        await losetup.detach(sh, rootPartition)


## Glossary : Backup means the original file on which a snapshot lie against

proc createSnapshot*(sh: ProcArgs, img, backup: Path, format: ImageFormat) {.async.} =
    ## Lighweight because incremental change
    ## Ensure the vm is not up and running
    await sh.rename(img, backup)
    await sh.runAssertDiscard(@["qemu-img", "create", "-f", $format, "-b", backup, img])

proc commitSnapshotChanges*(sh: ProcArgs, snapshot: Path) {.async.} =
    await sh.runAssertDiscard(@["qemu-img", "commit", snapshot])

proc changeSnapshotBackupFile*(sh: ProcArgs, snapshot, backup: Path) {.async.} =
    ## Use mvSnapshotBackup if possible
    await sh.runAssertDiscard(@["qemu-img", "rebase", "-b", backup, snapshot])

proc mvSnapshotBackup*(sh: ProcArgs, snapshot, backupSrc, backupDest: Path) {.async.} =
    await sh.rename(backupSrc, backupDest)
    await sh.changeSnapshotBackupFile(snapshot, backupDest)