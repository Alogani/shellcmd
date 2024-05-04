import ./coreutils

DependencyPackages.linux.add "cryptsetup"


proc luksEncrypt*(sh: ProcArgs, path: Path, luks1 = false): Future[void] =
    sh.runDiscard(@["cryptsetup", "luksFormat"] & (
        if luks1:
            @["--type", "luks1"]
        else:
            @[]
        ) & @[ $path ])