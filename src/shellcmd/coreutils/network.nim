import ./file/[filecontent]
import ./[common]

proc setHostname*(sh: ProcArgs, name: string): Future[void] =
    sh.writeFile("/etc/hostname", name)
