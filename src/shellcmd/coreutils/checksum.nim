import ./[common]

type Algorithm* = enum
    Sha256, Md5

const cmdTable = {
    Sha256: "sha256sums",
    Md5: "md5sums"
}.toTable()


proc getChecksum*(sh: ProcArgs, algo: Algorithm, file: string): Future[string] =
    sh.runGetOutput(@[cmdTable[algo], file], internalCmd)

proc verifyWithFileList*(sh: ProcArgs, algo: Algorithm, file: string): Future[bool] =
    sh.runCheck(@[cmdTable[algo], "--ignore-missing", "-c", file], internalCmd)
