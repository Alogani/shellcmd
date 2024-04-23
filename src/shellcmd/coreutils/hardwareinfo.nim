import std/json
import aloganimisc/jsonhelper
import ./file/[filemanagement]
import ./[common]


proc listUsbInfo*(sh: ProcArgs): Future[JsonNode] {.async.} =
    let devices = await sh.runGetLines(@["find", "/dev/bus/usb", "-mindepth", "2", "-maxdepth", "2"], internalCmd)
    result = %* {"udevadm": newJObject(), "lsusb": newJObject()}
    for device in devices:
        result["udevadm"][device] = %* await sh.runGetOutput(@["udevadm", "info", "--name", device], internalCmd)
        result["lsusb"][device] = %* await sh.runGetOutput(@["lsusb", "-D", device], internalCmd)

proc listPciInfo*(sh: ProcArgs): Future[JsonNode] {.async.} =
    let devices = await sh.ls("/sys/bus/pci/devices")
    result = %* {"udevadm": newJObject(), "lsusb": newJObject()}
    for device in devices:
        result["udevadm"][device] = %* await sh.runGetOutput(@["udevadm", "info", "--class", device], internalCmd)
        result["lsusb"][device] = %* await sh.runGetOutput(@["lsusb", "-D", device], internalCmd)

proc listHardware*(sh: ProcArgs): Future[JsonNode] {.async.} =
    result = newJObject()
    var data = parseJson await sh.runGetOutput(@["lshw", "-json"], internalCmd.merge(toRemove = { MergeStderr }))
    return data.flattenJsonDict("id", "children")


