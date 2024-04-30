import ./coreutils


proc loadkmap*(sh: ProcArgs, src: Path): Future[void] =
    ## Low level, useful for initramfs
    let kmapData = sh.readFileToStream(src)
    sh.runDiscard(@["loadkmap"], internalCmd.merge(input = some kmapData))

proc dumpkmap*(sh: ProcArgs, dest: Path): Future[void] =
    ## Low level, useful for initramfs
    ## Nice hack : if command executed after chroot, will dump the actual keyboard
    let (kmapData, finishFut) = sh.runGetOutputStream(@["dumpkmap"], internalCmd)
    sh.writeFileFrom(dest, kmapData) and finishFut
