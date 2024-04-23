import ./file/[filecontent]
import ./[common]


type Distro* = enum
    Debian, Fedora, ArchLinux

proc getDistroName*(sh: ProcArgs): Future[Distro] {.async.} =
    for line in await(sh.readLines("/etc/os-release")):
        if line.startsWith("ID="):
            var distroName = line[3 .. ^1]
            if distroName == "debian":
                return Debian
            elif distroName == "fedora":
                return Fedora
    raise newException(OSError, "Unknown distro")

## uname can provid more info