import ./coreutils
import ./private/dependencyhandler


DependencyPackages.linux.add("pax-utils")

proc whereIsBinary*(sh: ProcArgs, cmd: string): Future[Path] {.async.} =
    let data = await sh.runGetOutput(@["whereis", "-b", cmd], internalCmd)
    return data.split(" ")[1]

proc getSharedLibrary*(sh: ProcArgs, cmd: string | Path): Future[seq[Path]] {.async.} =
    let path = if cmd is string: await sh.whereIsBinary(cmd) else: cmd
    let data = await sh.runGetLines(@["lddtree", "-l", path], internalCmd)
    return seq[Path](data[1 .. ^1])
