import ./coreutils


proc luksEncrypt*(sh: ProcArgs, path: Path, luks1 = false): Future[void] =
    sh.runAssertDiscard(@["cryptsetup", "luksFormat"] & (
        if luks1:
            @["--type", "luks1"]
        else:
            @[]
        ) & @[ $path ])