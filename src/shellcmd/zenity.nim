import ./coreutils

# Will only work if a display is associated with terminal. See DISPLAY env variable


proc askPassword*(sh: ProcArgs): Future[string] =
    sh.runGetOutput(@["zenity, --password"], internalCmd)


proc listBox*(sh: ProcArgs, choices: openArray[string], title = ""): Future[string] =
    sh.runGetOutput(@["zenity", "--list", "--column", title] & @choices, internalCmd)
