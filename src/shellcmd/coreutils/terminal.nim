import ./[common]

proc clearTerminal*(sh: ProcArgs): Future[void] =
    sh.runAssertDiscard(@["clear"], internalCmd)