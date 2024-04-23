import ./[common]

## Don't persist on reboot, except explictly told


proc acceptIncomming*(sh: ProcArgs, address: string, port: int): Future[void] =
    sh.runAssertDiscard(@["iptables", "-I", "INPUT", "-s", address, "-dport", $port, "-j", "ACCEPT"], internalCmd)

proc forward*(sh: ProcArgs, addressA, addressB: string; port: int): Future[void] =
    sh.runAssertDiscard(@["iptables", "-I", "FORWARD", "-s", addressA, "-d", addressB, "-dport", $port, "-j", "ACCEPT"],
        internalCmd)