import std/random
import ./file/[filecontent, filemanagement]
import ./[common]

import aloganimisc/macrosmisc

{. warning[UnusedImport]:off.}

var RandomGenerator: ref Rand
const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


proc createTempDir*(sh: ProcArgs): Future[Path] =
    sh.runGetOutput(@["mktemp", "-d"], internalCmd)

proc createTempFile*(sh: ProcArgs): Future[Path] =
    sh.runGetOutput(@["mktemp"], internalCmd)

proc genTempPath*(tempdir: Path, len = 10, prefix = "", suffix = ""): Path =
    ## Don't use outside of a tempdir for security reason
    # Hideously copied from std/tempfiles source code ;) with some twist
    if RandomGenerator == nil:
        RandomGenerator = newRefOf initRand()
    var res = newString(len)
    for i in 0 ..< len:
        res[i] = RandomGenerator[].sample(letters)
    return Path(res)

template withNewTempDir*(sh: ProcArgs, path, body: untyped) {.dirty.} =
    let path = await sh.createTempDir()
    defer: await sh.unlink(path)
    body

template withNewTempFile*(sh: ProcArgs, path, body: untyped) {.dirty.} =
    let path = await sh.createTempFile()
    defer: await sh.unlink(path)
    body
