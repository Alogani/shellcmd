import std/strformat
import ./coreutils
import ./private/dependencyhandler

DependencyPackages.linux.add("sshfs")


type MountOptions* = enum
    AllowOther, OptPerformance


proc getCommand*(address: string, forcePty = false): seq[string] =
    ## Force Pty is useful for job control if launched interactively
    if forcePty:
        @["ssh", "-t", address] #-> will works for interactive
    else:
        @["ssh", address]
    # Use sshpass to provide password.

proc mount*(sh: ProcArgs, address: string, mountpoint: Path, port=22, mountoptions = { AllowOther, OptPerformance }) {.async.} =
    let optionsStr = "" &
            (if AllowOther in mountoptions: "allow_other," else: ""
        ) & "reconnect,auto_cache" &
            (if OptPerformance in mountoptions: ",Ciphers=aes128-gcm@openssh,Compression=no" else: ""
        )
    await sh.runAssertDiscard(@["sshfs", "-p", $port] & (
        if optionsStr != "":
            @["-o", optionsStr]
        else:
            @[]
    ) & @[address & ":/", $mountpoint])

proc tunnel*(sh: ProcArgs, serverAddr: string, sshPort=22; clientExitPort, serverEntryPort: int) {.async.} =
    await sh.runAssertDiscard(@["ssh", "-p", $sshPort, "-L",
        fmt"127.0.0.1:{clientExitPort}:127.0.0.1:{serverEntryPort}",
        serverAddr])

#[
echo repr waitFor sh.run(@["sshpass", "-p", "nPASSWORD", "ssh", "clement@localhost", "read a; echo a=$a"], ProcArgsModifier(
        toAdd: {CaptureInput, Daemon}, toRemove: {QuoteArgs, Interactive},
        env: some {"PS1": "bash$ "}.toTable(),
        input: some (AsyncChainReader.new(AsyncString.new("blah\n"), stdinAsync).AsyncIoBase, false)))

    ]#