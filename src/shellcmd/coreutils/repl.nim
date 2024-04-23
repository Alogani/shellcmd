import ./[common]


proc execBash*(sh: ProcArgs, argsModifier = ProcArgsModifier(), prompt = "bash$ "): Future[ProcResult] =
    ## Convenient function to get a terminal inside a script
    return sh.run(@["bash", "--norc", "-i"], argsModifier.merge(
        toAdd = { Interactive },
        envModifier = some {"PS1": prompt, "TERM": "xterm"}.toTable()
    ))

proc execPython*(sh: ProcArgs, argsModifier = ProcArgsModifier()): Future[ProcResult] =
    return sh.run(@["python"], argsModifier.merge(
        toAdd = { Interactive },
    ))