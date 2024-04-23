import std/json
import ./[common]


type
    IPV4Address* = distinct string
    IPV6Address* = distinct string
    MACAddress* = distinct string

    DeviceFlags* = enum
        Up, LoopBack

    NetworkInterface* = object
        name: string
        flags: set[DeviceFlags]
        mac: MacAddress
        localIPV4: IPV4Address
        broadcastIPV4: IPV4Address
        localIPV6: IPV6Address
        broadcastIPV6: IPV6Address

    RouteInfo* = object
        destination: string
        source: string
        gateway: string
        interfaceName: string
        protocol: string


converter toIPV4Address*(str: string): IPV4Address = IPV4Address(str)
converter toIPV6Address*(str: string): IPV6Address = IPV6Address(str)
converter toMacAddress*(str: string): MACAddress = MACAddress(str)


proc getDevicesInfo*(sh: ProcArgs): Future[seq[NetworkInterface]] {.async.} =
    let jsonNode = parseJson await sh.runGetOutput(@["ip", "-j", "addr", "show"], internalCmd)
    for dev in jsonNode.getElems():
        result.add NetworkInterface(
            name: dev{"ifname"}.getStr(),
            flags: (
                (if dev{"flags"}.contains(%"LOOPBACK"): {LoopBack} else: {}) +
                (if dev{"operstate"}.getStr() == "UP": { Up } else: {})
            ),
            mac: dev{"address"}.getStr(),
            localIPV4: dev{"addr_info"}{0}{"local"}.getStr(),
            broadcastIPV4: dev{"addr_info"}{0}{"broadcast"}.getStr(),
            localIPV6: dev{"addr_info"}{1}{"local"}.getStr(),
            broadcastIPV6: dev{"addr_info"}{1}{"broadcast"}.getStr()
        )

proc getRouteInfo*(sh: ProcArgs): Future[seq[RouteInfo]] {.async.} =
    let jsonNode = parseJson await sh.runGetOutput(@["ip", "-j", "route", "show"], internalCmd)
    for route in jsonNode.getElems():
        result.add RouteInfo(
            destination: route{"dst"}.getStr(),
            source: route{"prefsrc"}.getStr(),
            gateway: route{"gateway"}.getStr(),
            interfaceName: route{"dev"}.getStr(),
            protocol: route{"protocol"}.getStr()
        )

proc enableInterface*(sh: ProcArgs, name: string): Future[void] =
    sh.runAssertDiscard(@["ip", "link", "set", name, "up"])

proc disableInterface*(sh: ProcArgs, name: string): Future[void] =
    sh.runAssertDiscard(@["ip", "link", "set", name, "down"])
