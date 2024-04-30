import ./coreutils


type DefaultChoice* = enum
    Yes, No, None

proc askYesNo*(sh: ProcArgs, text: string, defaultChoice = DefaultChoice.None, withShellChoice = true): Future[bool] {.async.} =
    while true:
        stdout.write(text)
        if withShellChoice:
            stdout.write " [sh/y/n]? "
        else:
            stdout.write " [y/n]? "
        stdout.flushFile()
        if defaultChoice == Yes: stdout.write "(y) " elif defaultChoice == No: stdout.write "(n) "
        let response = (await stdinAsync.readLine()).normalize()
        if response == "":
            if defaultChoice == Yes: return true
            if defaultChoice == No: return false
        if response in ["y", "yes"]:
            return true
        if response in ["n", "no"]:
            return false
        if withShellChoice and response in ["sh", "shell", "bash"]:
            discard await sh.execBash()
            stdout.write("\n")
        else:
            echo "Response is not in available choice. Please try again.\n"


proc askListChoice*(sh: ProcArgs, text: string, choiceCount: Positive, defaultChoice = 0, withShellChoice = true): Future[int] {.async.} =
    var choiceStr = newStringOfCap(choiceCount * 2)
    for i in 1 .. choiceCount: choiceStr.add "/" & $i
    while true:
        stdout.write(text)
        if withShellChoice:
            stdout.write " [sh" & choiceStr & "]? "
        else:
            stdout.write " [" & choiceStr & "]? "
        if defaultChoice > 0:
            stdout.write "(" & $defaultChoice & ") "
        stdout.flushFile()
        let response = (await stdinAsync.readLine()).normalize()
        if response == "" and defaultChoice > 0:
            return defaultChoice
        try:
            let responseInt = response.parseUInt().int()
            if responseInt > 0 and responseInt <= choiceCount:
                return responseInt
        except: discard
        if withShellChoice and response in ["sh", "shell", "bash"]:
            discard await sh.execBash()
            stdout.write("\n")
        else:
            echo "Response is not in available choice. Please try again.\n"

proc askString*(sh: ProcArgs, text: string): Future[string] {.async.} =
    while true:
        echo text
        echo "A shell will spawn. Please echo the response and then exit 0 to validate it"
        echo r"If response contains a newline, use : echo ""${MYVAR//$'\n'/\\n}"""
        var procRes = await sh.execBash(ProcArgsModifier(toAdd: { CaptureOutput }))
        if not procRes.success:
            if await sh.askYesNo("Shell did not exit successfully. Shall it raise", No, withShellChoice = false):
                raise newException(OSError, "Invalid user input")
        let responseSeq = procRes.output.rsplit('\n', 2)
        let response = if responseSeq.len > 1: responseSeq[^2].replace(r"\n", "\n") else: ""
        if await sh.askYesNo("> Here is your response :\n" & response & "\n> Do you confirm", No, withShellChoice = false):
            return response
        

