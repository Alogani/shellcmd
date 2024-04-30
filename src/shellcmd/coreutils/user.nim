import ./[common]

type
    User*[Interpreter: ProcArgs] = object
        sh: Interpreter
        name: string

type AddOptions* = enum
    CreateHome, IsSystem


proc init*[Interpreter: ProcArgs](T: type User, sh: Interpreter, name: string): User =
    User(sh: sh, name: name)

proc setPassword*(user: User, passwd: string): Future[void] =
    user.sh.runDiscard(@["passwd", user.name], internalCmd.merge(
        input = (AsyncString.new(passwd & "\n" & passwd & "\n").AsyncIoBase, false)
    ))

proc appendGroups*(user: User, groups: varargs[string]): Future[void] =
    user.sh.runDiscard(@["usermod", "-a", "-G", groups.join(",")], internalCmd)

proc add*(user: User, shell: string = "", options: set[AddOptions]): Future[void] =
    user.sh.runDiscard(@["useradd"] &
        (if CreateHome in options: @["-m"] else: @[""]) &
        (if shell != "": @["-s", shell] else: @[""]) &
        (if IsSystem in options: @["-r"] else: @[""]),
        internalCmd
    )
