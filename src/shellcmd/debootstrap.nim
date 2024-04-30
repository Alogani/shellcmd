import ./coreutils

type
    Arch* = enum
        Amd64 = "amd64"

    Variant* = enum
        MinBase = "minbase", Buildessential = "buildd"

    Release* = enum
        Stable = "stable", Unstable = "sid"

proc debootstrap*(sh: ProcArgs, path: Path, arch = Amd64, variant = MinBase,
            release = Stable, mirror = "http://ftp.fr.debian.org/debian/"): Future[void] =
    sh.runDiscard(@["debootstrap", "--arch=" & $arch, "--variant=" & $variant,
        $release, path, mirror])