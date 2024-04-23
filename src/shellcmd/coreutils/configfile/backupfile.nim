import std/[times, algorithm]
import ../file/[filemanagement]
import ../[common]

const
    BackupString = ".back_"
    DateTimeFormat = "yyyy-MM-dd'T'HH:mm:sszzz"


proc backupFile*(sh: ProcArgs, path: Path): Future[void] =
    sh.cp(path, path & BackupString & getTime().format(DateTimeFormat))

proc listAllBackups*(sh: ProcArgs, path: Path, order = Descending): Future[seq[Path]] {.async.} =
    let files = await sh.ls(path.parentDir)
    var fileAndDate = collect:
        for f in files:
            if f.extractFilename().startsWith(path):
                let idx = f.find(BackupString)
                if idx != -1:
                    (
                        time: f[idx + BackupString.len() .. ^1]
                            .parse(DateTimeFormat).toTime().toUnix(),
                        path: f
                    )
    fileAndDate.sort (a, b: auto) => cmp(a.time, b.time), order
    result = collect:
        for x in fileAndDate:
            x.path

proc restoreLastBackup*(sh: ProcArgs, path: Path): Future[bool] {.async.} =
    let backups = await sh.listAllBackups(path)
    if backups.len() == 0:
        false
    else:
        try:
            await sh.cp(backups[0], path, overwrite = true)
            true
        except: false

