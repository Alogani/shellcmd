import file/[filemanagement]
import ./[common, compression]


proc cpioCreate*(sh: ProcArgs, src, dest: Path) {.async.} =
    if await sh.exists(dest): raise newException(OSError, "Destination already exists")
    let destAbsolute = await sh.absolutePath(dest)
    await sh.runAssertDiscard(@["sh", "-c", "cd " & quoteShell(src) & " && find . | cpio --create -c -R root:root -F " & destAbsolute],
        ProcArgsModifier(toRemove: { QuoteArgs })
    )

proc cpioExtract*(sh: ProcArgs, src, dest: Path) {.async.} =
    await sh.mkdir(dest, parents = true)
    if not await sh.isDirEmpty(dest): raise newException(OSError, "Destination already exists")
    await sh.runAssertDiscard(@["cpio", "--extract", "-D", dest, "-F", src])


proc tarCreate*(sh: ProcArgs, src, dest: Path, algo: Algorithm = NoCompression) {.async.} =
    let destAbsolute = await sh.absolutePath(dest)
    await sh.runAssertDiscard(@["tar"] & (
            case algo:
            of NoCompression:
                @[]
            of Bzip2:
                @["--bzip2"]
            of Gzip:
                @["--gzip"]
            of Xz:
                @["--xz"]
            of Zstd:
                @["--zstd"]
            #else:
            #    raise newException(OSError, "Compression algorithm not available")
        ) & @["-C", src, "--acls", "--xattrs", "--one-file-system", "-cf", destAbsolute, "."])

proc tarExtract*(sh: ProcArgs, src, dest: Path, algo: Algorithm = NoCompression) {.async.} =
    await sh.mkdir(dest, parents = true)
    if not await sh.isDirEmpty(dest): raise newException(OSError, "Destination already exists")
    await sh.runAssertDiscard(@["tar"] & (
            case algo:
            of NoCompression:
                @[]
            of Bzip2:
                @["--bzip2"]
            of Gzip:
                @["--gzip"]
            of Xz:
                @["--xz"]
            of Zstd:
                @["--zstd"]
            #else:
            #    raise newException(OSError, "Compression algorithm not available")
        ) & @["-xf", src, "-C", dest])