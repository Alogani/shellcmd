import ./[common]

proc clearTerminal*(sh: ProcArgs): Future[void] =
    sh.runDiscard(@["clear"], internalCmd)