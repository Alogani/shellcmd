import ./private
export ImageFormat

type
    QvmRunOption* = enum
        WithBootMenu, EnableKVM

    PortForwarding* = object
        hostPort: int
        guestPort: int
        protocol = "tcp"

proc startVM*(sh: ProcArgs, mainDisk: Path, format: Imageformat,
runOptions: set[QvmRunOption] = {},
cdromDisk = EmptyPath,
forwardings: seq[PortForwarding] = @[],
ram = 512.MB,
cpuCount = 1
) {.async.} =
    await sh.runDiscard(concat(@["qemu-system-x86_64",
            "-m", ram.toQemuString(),
            "-smp", $cpuCount,
            "-drive",
                "file=" & mainDisk &
                ",format=" & $format &
                ",index=0,media=disk",
        ],
        (if cdromDisk != EmptyPath: @["-drive",
            "file=" & cdromDisk &
            ",media=cdrom"
            ] else: @[]),
        (block:
            var res = newSeq[string]()
            for forward in forwardings:
                res.add @["-nic", "user,hostfwd=" & forward.protocol &
                    "::" & $forward.hostPort & "-:" & $forward.guestPort]
            res),
        (if WithBootMenu in runOptions: @["-boot", "menu=on"] else: @[]),
        (if EnableKVM in runOptions: @["-enable-kvm"] else: @[]),
    ))
