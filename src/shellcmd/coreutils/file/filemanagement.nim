import ../common
import ./fileinfo

const DevNull* = "/dev/null"
const DevURandom* = "/dev/urandom"


proc exists*(sh: ProcArgs, path: Path): Future[bool] =
    sh.runCheck(@["test", "-e", $path], internalCmd)

proc touch*(sh: ProcArgs, path: Path): Future[void] =
    sh.runDiscard(@["touch", $path], internalCmd)

proc unlink*(sh: ProcArgs, paths: seq[Path], nofail = false): Future[void] {.async.} =
    ## Danger: will not ask any permission. Use rmtree to delete a non empty dir
    if nofail:
        discard await sh.run(@["rm", "-f"] & seq[string](paths), internalCmd)
    else:
        await sh.runDiscard(@["rm", "-f"] & seq[string](paths), internalCmd)

proc unlink*(sh: ProcArgs, path: Path, nofail = false): Future[void] =
    sh.unlink(@[path], nofail)

proc shred*(sh: ProcArgs, paths: seq[Path], iterations = 3): Future[void] =
    sh.runDiscard(@["shred", "-f", "-u", "-n", $iterations] & seq[string](paths))

proc shred*(sh: ProcArgs, path: Path, iterations = 3): Future[void] =
    sh.shred(@[path], iterations)

proc mkdir*(sh: ProcArgs, path: Path, parents = false, octal_mode = ""): Future[void] =
    ## Raise error if directory exists and parent is set to false
    sh.runDiscard(@["mkdir", $path] &
        (if parents: @["-p"] else: @[]) &
        (if octal_mode != "": @["-m", octal_mode] else: @[])
    , internalCmd)

proc rmdir*(sh: ProcArgs, path: Path): Future[void] =
    sh.runDiscard(@["rmdir", $path], internalCmd)

proc rmtree*(sh: ProcArgs, path: Path): Future[void] =
    ## Danger, will not ask any permission
    sh.runDiscard(@["rm", "-rf", $path], internalCmd)

proc cp*(sh: ProcArgs, src, dest: Path, overwrite = false,
followSymLinks = false, preserveAttributes = true) {.async.} =
    if await exists(sh, dest):
        if not overwrite:
            raise newException(ExecError, "File already exists")
        await rmtree(sh, dest)
    await sh.runDiscard(@["cp", "-r"] &
        (if followSymLinks: @["-L"] else: @["-P"]) &
        (if preserveAttributes: @["-a"] else: @[]) &
        @[$src, $dest], internalCmd)

proc rename*(sh: ProcArgs, src, dest: Path, overwrite: bool = false) {.async.} =
    if await sh.exists(dest):
        if not overwrite:
            raise newException(ExecError, "File already exists")
        await rmtree(sh, dest)
    await sh.runDiscard(@["mv", $src, $dest], internalCmd)

proc dd*(sh: ProcArgs, src, dest: Path, append = false, count = -1, blockSize = 4.Mb): Future[void] =
    sh.runDiscard(@["dd", "if=" & src, "status=none"] &
        (if append: @["oflag=append", "conv=notrunc"] else: @[]) &
        (if count != -1: @["count=" & $count] else: @[]) &
        @["bs=" & blockSize.toString(suffix = "")] &
        @["of=" & dest])

proc wipeDisk*(sh: ProcArgs, dest: Path, useSource = DevNull): Future[void] {.async.} =
    var
        sectors = parseInt(await sh.getBlockDevInfo(dest, NumberOf512Sectors))
        idealSectorSize =  parseInt(await sh.getBlockDevInfo(dest, KernelBlockSize))
    if idealSectorSize != 512 and sectors mod idealSectorSize == 0:
        sectors = sectors div 512 * idealSectorSize
    else:
        idealSectorSize = 512
    sh.dd(useSource, dest, count = sectors, blockSize = idealSectorSize)

proc symlinkTo*(sh: ProcArgs, src, dest: Path): Future[void] =
    # Careful between absolute and relative
    sh.runDiscard(@["ln", "-s", $src, $dest], internalCmd)

proc ls*(sh: ProcArgs, path: Path, sort = true): Future[seq[Path]] {.async.} =
    ## Use find instead of ls. Notable difference is that if path is a file, it won't be returned
    ## Sort is natural sort
    var data = await sh.runGetLines(@["ls", $path, "-1"] & (
            (if sort: @["-v"] else: @["-U"])
        ), internalCmd)
    if data.len() == 1 and data[0] == "":
        return
    else:
        return seq[Path](data)

proc isDirEmpty*(sh: ProcArgs, path: Path): Future[bool] {.async.} =
    await(sh.ls(path)).len() == 0

proc mkfifo*(sh: ProcArgs, path: Path): Future[void] =
    sh.runDiscard(@["mkfifo", path])

template withFifo*(sh: ProcArgs, path: Path, body: untyped) =
    await sh.mkfifo(path)
    defer: await sh.unlink(path)
    body