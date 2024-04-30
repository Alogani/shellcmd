import ../common


proc readFileInto*(sh: ProcArgs, path: Path, dest: AsyncIOBase, closeStream = false): Future[void] =
    # best way to async is spawning a thread, shall not be too expensive
    var fut = sh.runDiscard(@["cat", $path], internalCmd.merge(output = some dest))
    if closeStream:
        return fut.then(proc() {.async.} = dest.close())
    else:
        return fut

proc readFileToStream*(sh: ProcArgs, path: Path): AsyncIoBase =
    var (stream, _) = sh.runGetOutputStream(@["cat", $path], internalCmd)
    return stream

proc readFile*(sh: ProcArgs, path: Path): Future[string] =
    sh.runGetOutput(@["cat", $path], internalCmd.merge(toAdd = { CaptureOutput }, toRemove = { CaptureInput }))

proc readLines*(sh: ProcArgs, path: Path): Future[seq[string]] {.async.} =
    splitLines await sh.readFile($path)

proc getWriteCmd(path: Path, append: bool): seq[string] =
    if append:
        return @["dd", "bs=4M",
            "oflag=append", "conv=notrunc",
            "status=none", "of=" & $path]
    return @["dd", "bs=4M",
            "status=none", "of=" & $path]

proc writeFileFrom*(sh: ProcArgs, path: Path, src: AsyncIOBase, append: bool = false): Future[void] =
    # If src is an unclosed stream or pipe, will cause a deadlock
    sh.runDiscard(getWriteCmd(path, append), internalCmd.merge(input = some src))

proc writeFile*(sh: ProcArgs, path: Path, data: string, append: bool = false): Future[void] =
    sh.writeFileFrom(path, AsyncString.new(data), append)

proc writeLines*(sh: ProcArgs, path: Path, lines: seq[string]): Future[void] =
    sh.writeFile(path, lines.join("\n"))

proc createSparseFile*(sh: ProcArgs, path: Path, size: StorageSize): Future[void] =
    ## You can use parseSize from parseutils to get size
    sh.runDiscard(@["truncate", "-s", size.toString(), $path], internalCmd)
