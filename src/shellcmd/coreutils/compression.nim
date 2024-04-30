import ./file/[filecontent, filemanagement]
import ./common

type Algorithm* = enum
    NoCompression
    Bzip2
    Gzip
    Xz
    Zstd


#[
    Does not provide the options to (un)compress to or from asynciostream:
        - Because inefficient
        - Cumbersome to code
        - Use mkfifo instead and use it as src or dest
        - use sh.readFile or sh.writeFile on the fifo
]#


proc compress*(sh: ProcArgs, src, dest: Path, algo: Algorithm) {.async.} =
    if await sh.exists(dest):
        raise newException(OSError, "Destination already exists")
    case algo:
    of Bzip2:
        var (stream, finishFut) = sh.runGetOutputStream(@["bzip2", "-zck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Gzip:
        var (stream, finishFut) = sh.runGetOutputStream(@["gzip", "-zck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Xz:
        var (stream, finishFut) = sh.runGetOutputStream(@["xz", "-zck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Zstd:
        await sh.runDiscard(@["zstd", "-zk", $src, "-o", $dest], internalCmd)
    else:
        raise newException(OSError, "Algorithm not implemented")


proc uncompress*(sh: ProcArgs, src, dest: Path, algo: Algorithm) {.async.} =
    if await sh.exists(dest):
        raise newException(OSError, "Destination already exists")
    case algo:
    of Bzip2:
        var (stream, finishFut) = sh.runGetOutputStream(@["bzip2", "-dck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Gzip:
        var (stream, finishFut) = sh.runGetOutputStream(@["gzip", "-dck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Xz:
        var (stream, finishFut) = sh.runGetOutputStream(@["xz", "-dck", $src], internalCmd)
        await sh.writeFileFrom(dest, stream) and finishFut
    of Zstd:
        await sh.runDiscard(@["unzstd", $src, "-o", $dest])
    else:
        raise newException(OSError, "Algorithm not implemented")
