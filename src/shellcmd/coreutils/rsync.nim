import ./[common]

type RsyncOptions* = enum
    Archive, Compress, SyncDeletion

proc rsync*(sh: ProcArgs, src, dest: Path, options: set[RsyncOptions] = {}, bandWith = -1): Future[void] =
    ## Bandwith is in Kb/s
    sh.runDiscard(@["rsync", "-r"] &
        (if Archive in options: @["--archive"] else: @[]) &
        (if Compress in options: @["--compress"] else: @[]) &
        (if SyncDeletion in options: @["--delete"] else: @[]) &
        (if bandWith != -1: @["--bwlimit=" & $bandWith] else: @[]) &
        @[if src[^1] == '/': src else: src & "/",
            if dest[^1] == '/': dest else: dest & "/"])