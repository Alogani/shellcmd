import ./coreutils
import ./private/dependencyhandler


DependencyPackages.linux.add("borgbackup")


proc initBackupDest*(sh: ProcArgs, dest, password: string): Future[ProcResult] =
    let envModifier = {
        "BORG_PASSWORD": password
    }.toTable()
    sh.runAssert(@["borg", "init", "--encryption", "repokey", dest], ProcArgsModifier(
        envModifier: some envModifier
    ))

proc createTask*(sh: ProcArgs, src, dest, password: string): Future[ProcResult] {.async.} =
    let envModifier = {
        "BORG_PASSWORD": password,
        "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK": "no",
        "BORG_RELOCATED_REPO_ACCESS_IS_OK": "no"
    }.toTable()
    await sh.runAssert(@["borg", "create", "--stats", "--compression=lz4",
        dest & "::'{hostname-now}'", src], ProcArgsModifier(envModifier: some envModifier)
    )

proc pruneTask*(sh: ProcArgs, dest, password: string): Future[ProcResult] =
    let envModifier = {
        "BORG_PASSWORD": password,
        "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK": "no",
        "BORG_RELOCATED_REPO_ACCESS_IS_OK": "no"
    }.toTable()
    sh.runAssert(@["borg", "prune", "--glob-archives='{hostname}-*'",
        "--keep-daily=7", "--keep-weekly=4", "--keep-monthly=6",
        dest], ProcArgsModifier(envModifier: some envModifier)
    )

proc compactTask*(sh: ProcArgs, dest, password: string): Future[ProcResult] =
    let envModifier = {
        "BORG_PASSWORD": password,
        "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK": "no",
        "BORG_RELOCATED_REPO_ACCESS_IS_OK": "no"
    }.toTable()
    sh.runAssert(@["borg", "compact", dest], ProcArgsModifier(envModifier: some envModifier))

proc doAllTasks*(sh: ProcArgs, src, dest, password: string): Future[ProcResult] {.async.} =
    merge(
        await sh.createTask(src, dest, password),
        await sh.pruneTask(dest, password),
        await sh.compactTask(dest, password)
    )
