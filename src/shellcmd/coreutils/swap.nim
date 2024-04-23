import ./file/[filecontent, fileinfo]
import ./configfile/fstab
import ./[common]


proc create*(sh: ProcArgs, path: Path, size: Storagesize) {.async.} =
    await sh.createSparseFile(path, size)
    await sh.chmod(path, "0600")
    await sh.runAssertDiscard(@["mkswap", "-U", "clear", path], internalCmd)
    await sh.runAssertDiscard(@["swapon", path], internalCmd)
    await fstab.addEntry(sh, path, "none", Swap, DefaultMountFlags, FsckOrder.Never)

proc remove*(sh: ProcArgs, path: Path) {.async.} =
    await sh.runAssertDiscard(@["swapoff", path], internalCmd)
    await sh.remove(path)
    if not await fstab.removeEntry(sh, path):
        raise newException(OSError, "Couldn't remove swap fstab entry")
