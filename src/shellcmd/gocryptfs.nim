import ./coreutils
import ./private/dependencyhandler


DependencyPackages.linux.add("gocryptfs")


proc initSecretFolder*(sh: ProcArgs, path, password: string): Future[string] =
    sh.runGetOutput(@["gocryptfs", "-init", path], ProcArgsModifier(input: some (AsyncString.new(password & "\n").AsyncIoBase, false)))

proc mountSecretFolder*(sh: ProcArgs, src, dest, password: string):Future[void] =
    sh.runAssertDiscard(@["gocryptfs", src, dest], ProcArgsModifier(input: some (AsyncString.new(password & "\n").AsyncIoBase, false)))