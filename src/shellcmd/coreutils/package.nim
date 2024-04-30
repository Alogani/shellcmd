import std/[os]
import ./[common, distro, systemctl]


proc install*(sh: ProcArgs, packages: varargs[string]) {.async.} =
    if packages.len() == 0: return
    await sh.runDiscard((case await sh.getDistroName():
        of Debian:
            @["apt", "install"]
        of Fedora:
            @["dnf", "install"]
        of ArchLinux:
            @["pacman", "-S"]
        ) & @packages
    )

proc installWithoutEnabling*(sh: ProcArgs, packages: varargs[string]) {.async.} =
    var servicesBefore = await systemctl.listRunningOrEnabled(sh)
    await sh.install(packages)
    sleep(2000)
    var servicesAfter = await systemctl.listRunningOrEnabled(sh)
    var unwantedServices = collect(newSeqOfCap(servicesAfter.len() -
            servicesBefore.len())):
        for service in servicesAfter:
            if service notin servicesBefore:
                service
    systemctl.stopAndDisable(sh, unwantedServices)


proc remove*(sh: ProcArgs, packages: varargs[string]) {.async.} =
    if packages.len() == 0: return
    await sh.runDiscard((case await sh.getDistroName():
        of Debian:
            @["apt", "autoremove"]
        of Fedora:
            @["dnf", "autoremove"]
        of ArchLinux:
            @["pacman", "-Rs"]
        ) & @packages
    )

proc removeAndPurge*(sh: ProcArgs, packages: varargs[string]) {.async.} =
    if packages.len() == 0: return
    await sh.runDiscard((case await sh.getDistroName():
        of Debian:
            @["apt", "autoremove", "--purge"]
        of Fedora: ## Fedora: Simple remove, no purge equivalent
            @["dnf", "autoremove"]
        of ArchLinux:
            @["pacman", "-Rns"]
        ) & @packages
    )

proc update*(sh: ProcArgs) {.async.} =
    await sh.runDiscard((case await sh.getDistroName():
        of Debian:
            @["apt", "update"]
        of Fedora:
            @["dnf", "upgrade"]
        of ArchLinux:
            @["pacman", "-Syu"]
        )
    )

proc clean*(sh: ProcArgs) {.async.} =
    await sh.runDiscard((case await sh.getDistroName():
        of Debian:
            @["apt", "clean"]
        of Fedora:
            @["dnf", "clean", "all"]
        of ArchLinux:
            @["pacman", "-Scc"]
        )
    )


proc installPip*(sh: ProcArgs, packages: varargs[string]) {.async.} =
    if packages.len() == 0: return
    await sh.runDiscard(@["python3", "-m", "pip", "install"] & @packages)
