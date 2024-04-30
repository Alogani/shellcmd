import ./[common, find]


proc attach*(sh: ProcArgs, path: Path, hasPartition = true): Future[seq[Path]] {.async.} =
    var availableLoopDev = await sh.runGetOutput(@["losetup", "-f"], internalCmd)
    #availableLoopDev.setLen(high(availableLoopDev))
    await sh.runDiscard(@["losetup", availableLoopDev, path] &
        (if hasPartition:
            @["-P"]
        else:
            @[]),
        internalCmd)
    result = await sh.find(availableLoopDev.parentDir, @[matchName(availableLoopDev.extractFileName() & "*")])

proc detach*(sh: ProcArgs, path: Path) {.async.} =
    await sh.runDiscard(@["losetup", "-d", path], internalCmd)
