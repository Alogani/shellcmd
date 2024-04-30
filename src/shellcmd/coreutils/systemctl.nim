import ./[common]


proc listRunning*(sh: ProcArgs): Future[seq[string]] {.async.} =
    var data = await sh.runGetLines(@["systemctl"])
    return collect(newSeq):
        for serviceInfo in data:
            if "running" in serviceInfo:
                serviceInfo.strip(trailing = false).split(" ")[0]

proc listEnabled*(sh: ProcArgs): Future[seq[string]] {.async.} =
    var data = await sh.runGetLines(@["systemctl", "list-unit-files"])
    return collect(newSeq):
        for serviceInfo in data:
            if "enabled" in serviceInfo:
                serviceInfo.strip(trailing = false).split(" ")[0]

proc listRunningOrEnabled*(sh: ProcArgs): Future[seq[string]] {.async.} =
    var data = await sh.runGetLines(@["systemctl", "list-unit-files"])
    return collect(newSeq):
        for serviceInfo in data:
            if "enabled" in serviceInfo or "running" in serviceInfo:
                serviceInfo.strip(trailing = false).split(" ")[0]

proc start(sh: ProcArgs, enable = false, services: varargs[string]) {.async.} =
    if services.len() == 0:
        return
    await sh.runDiscard(@["systemctl", "start"] & @services)
    if enable:
        await sh.runDiscard(@["systemctl", "enable"] & @services)

proc start*(sh: ProcArgs, services: varargs[string]): Future[void] =
    sh.start(enable = false, services)

proc startAndEnable*(sh: ProcArgs, services: varargs[string]): Future[void] =
    sh.start(enable = true, services)

proc stop(sh: ProcArgs, disable = false, services: varargs[string]) {.async.} =
    if services.len() == 0:
        return
    await sh.runDiscard(@["systemctl", "stop"] & @services)
    if disable:
        await sh.runDiscard(@["systemctl", "disable"] & @services)

proc stop*(sh: ProcArgs, services: varargs[string]): Future[void] =
    sh.stop(disable = false, services)

proc stopAndDisable*(sh: ProcArgs, services: varargs[string]): Future[void] =
    sh.stop(disable = true, services)

proc restart*(sh: ProcArgs, services: varargs[string]): Future[void] =
    if services.len() == 0: return
    sh.runDiscard(@["systemctl", "restart"] & @services)

proc reload*(sh: ProcArgs, services: varargs[string]): Future[void] =
    if services.len() == 0: return
    sh.runDiscard(@["systemctl", "reload"] & @services)

proc daemonReload*(sh: ProcArgs): Future[void] =
    sh.runDiscard(@["systemctl", "deamon-reload"])