import ./file/[filemanagement]
import ./[common, mount]


proc withChroot*[T: ProcArgs](sh: T, path: Path): T =
    result = sh.deepcopy()
    result.prefixCmd = @["chroot", path]

proc bindAPIFs*(sh: ProcArgs, path: Path, APIFs = @["/proc", "/dev", "/sys", "/run"], create = false) {.async.} =
    for hostPath in APIFs:
        if create:
            await sh.mkdir(path/hostpath, true)
        await sh.mount(hostPath, path/hostPath, bindMount = true)

proc unbindAPIFs*(sh: ProcArgs, path: Path, APIFs = @["/proc", "/dev", "/sys", "/run"]) {.async.} =
    for hostPath in APIFs:
        await sh.umount(path/hostPath)
