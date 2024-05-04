import ./[common, find]


proc attachLoopDev*(sh: ProcArgs, path: Path): Future[Path] {.async.} =
    var availableLoopDev = await sh.runGetOutput(@["losetup", "-f"], internalCmd)
    #availableLoopDev.setLen(high(availableLoopDev))
    await sh.runDiscard(@["losetup", availableLoopDev, path], internalCmd)
    return availableLoopDev

proc attachLoopDevWithPartitions*(sh: ProcArgs, path: Path): Future[seq[Path]] {.async.} =
    var availableLoopDev = await sh.runGetOutput(@["losetup", "-f"], internalCmd)
    #availableLoopDev.setLen(high(availableLoopDev))
    await sh.runDiscard(@["losetup", availableLoopDev, path, "-P"], internalCmd)
    return await sh.find(availableLoopDev.parentDir, @[matchName(availableLoopDev.extractFileName() & "*")])

proc detachLoopDev*(sh: ProcArgs, path: Path) {.async.} =
    await sh.runDiscard(@["losetup", "-d", path], internalCmd)
