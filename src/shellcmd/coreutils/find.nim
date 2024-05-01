import ./common
import ./file/fileinfo

import aloganimisc/seqmisc
import std/strutils


type Filter = distinct seq[string]
type NumArg = distinct string

type FindUnit* = enum # Not directly convertible to StorageUnit
    NoUnit = "", Block = "b", Bytes = "c", TwoByteWord = "w", KiB = "k", MiB = "M", GiB = "G"
type DateRecord* = enum
    AttributeChange = "ctime"
    Modification = "mtime"
    Access = "atime"


proc Greater*(n: int): NumArg
proc Lesser*(n: int): NumArg
proc Exactly*(n: int): NumArg

proc `not`*(filter: Filter): Filter
proc `or`*(filterA, filterB: Filter): Filter
proc excludeDirContent*(filter: Filter): Filter
proc group*(filters: varargs[Filter]): Filter
proc matchName*(pattern: string, caseSensitive = false): Filter
proc matchPath*(pattern: string, caseSensitive = false): Filter
proc matchRegex*(pattern: string, caseSensitive = false): Filter
proc isEmpty*(): Filter
proc isReadable*(): Filter
proc isWritable*(): Filter
proc isExecutable*(): Filter
proc isSamefileAs*(path: Path): Filter
proc isNewerThan*(path: Path, dateType: DateRecord): Filter
proc hasTypes*(fileType: seq[FileType]): Filter
proc hasInode*(num: NumArg): Filter
proc hasUserId*(num: NumArg): Filter
proc hasUserName*(name: string): Filter
proc hasGroupId*(num: NumArg): Filter
proc hasGroupName*(name: string): Filter
proc hasSize*(num: NumArg, unit: FindUnit): Filter
proc wasModifiedMinutes*(num: NumArg, dateType: DateRecord): Filter
proc wasModifiedDays*(num: NumArg, dateType: DateRecord): Filter

proc fileTypToArg(fileType: FileType): string
proc toSeqString(filters: seq[Filter]): seq[string]


proc find*(sh: ProcArgs, path: Path, filters: seq[Filter] = @[], mindepth = -1, maxdepth = -1, followSymlinks = false, ditchRootName = false): Future[seq[Path]] {.async.} =
    ## Adding multiple filters is equivalent to "and"
    ## Due to simplification, no positional argument modifier like -wasModifiedDaystart have been implemented
    var data = await sh.runGetOutput(@["find"] &
        (if followSymlinks: @["-L"] else: @["-P"]) &
        (if mindepth >= 0: @["-mindepth", $mindepth] else: @[]) &
        (if maxdepth >= 0: @["-maxdepth", $maxdepth] else: @[]) &
        @[$path] &
        filters.toSeqString() &
        (if ditchRootName: @["-printf", "%P\\0"] else: @["-print0"]),
    internalCmd)
    data.setLen(data.len() - 1) # Remove trailing "\0"
    return cast[seq[Path]](data.split("\0"))


proc Greater*(n: int): NumArg = NumArg("+" & $n)
proc Lesser*(n: int): NumArg = NumArg("-" & $n)
proc Exactly*(n: int): NumArg = NumArg($n)
converter toNumArg*(n: int): NumArg = NumArg($n)


proc `not`*(filter: Filter): Filter =
    Filter(@["-not"] & cast[seq[string]](filter))

proc `or`*(filterA, filterB: Filter): Filter =
    Filter(cast[seq[string]](filterA) & @["-or"] & cast[seq[string]](filterB)) 

proc excludeDirContent*(filter: Filter): Filter =
    ## Don't exclude a dir but its content
    ## Careful to those deceptive behaviours:
    ##  - will only return true if filter is true, so to use with other filters, use `or`
    ##  - must be put before other filters, otherwise filters before will be ignored
    ##  - Using it more than once result in unexpected behaviour (use more complex argument instead)
    group(filter, Filter(@["-prune"]))

proc group*(filters: varargs[Filter]): Filter =
    Filter(@["("] & @filters.toSeqString() & @[")"])

proc hasTypes*(fileType: seq[FileType]): Filter =
    var typList: seq[string]
    for typ in fileType:
        typList.add fileTypToArg(typ)
    return Filter(@["-type"] & typList.join(","))


proc isEmpty*(): Filter =
    ## Could match either a regular file or a directoty
    Filter(@["-empty"])

proc isReadable*(): Filter =
    # See isExecutable for more info
    Filter(@["-readable"])

proc isWritable*(): Filter =
    # See isExecutable for more info
    Filter(@["-writable"])

proc isExecutable*(): Filter =
    ## Could match either a regular file or a directoty
    ## Use permissions of the current user
    Filter(@["-executable"])

proc matchName*(pattern: string, caseSensitive = false): Filter =
    ## Use sheel pattern. see find manual for more info
    Filter(
        if caseSensitive:
            @["-name", pattern]
        else:
            @["-iname", pattern]
    )

proc matchPath*(pattern: string, caseSensitive = false): Filter =
    Filter(
        if caseSensitive:
            @["-path", pattern]
        else:
            @["-ipath", pattern]
    )

proc matchRegex*(pattern: string, caseSensitive = false): Filter =
    Filter(
        if caseSensitive:
            @["-regex", pattern]
        else:
            @["-iregex", pattern]
    )

proc hasInode*(num: NumArg): Filter =
    Filter(@["inum", num.string])

proc isSamefileAs*(path: Path): Filter =
    ## Must be accessible by find command
    ## if file have same hasInode
    Filter(@["-samefile", path])

proc hasUserId*(num: NumArg): Filter =
    Filter(@["-uid", num.string])

proc hasUserName*(name: string): Filter =
    Filter(@["-user", name])

proc hasGroupId*(num: NumArg): Filter =
    Filter(@["-gid", num.string])

proc hasGroupName*(name: string): Filter =
    Filter(@["-group", name])

proc hasSize*(num: NumArg, unit: FindUnit): Filter =
    Filter(@["-hasSize", num.string & $unit])

proc isNewerThan*(path: Path, dateType: DateRecord): Filter =
    ## Must be accessible by find command
    Filter(
        case dateType:
        of AttributeChange:
            @["-cnewer", path]
        of Modification:
            @["-newer", path]
        of Access:
            @["-anewer", path]
    )

proc wasModifiedMinutes*(num: NumArg, dateType: DateRecord): Filter =
    ## Be careful, no fraction is allowed, see filterDays
    Filter(
        case dateType:
        of AttributeChange:
            @["-cmin", num.string]
        of Modification:
            @["-mmin", num.string]
        of Access:
            @["-amin", num.string]
    )

proc wasModifiedDays*(num: NumArg, dateType: DateRecord): Filter =
    ## Be careful, no fraction is allowed in matching file
    ## For example, if num = Greather(1), the file would have been modified at least two wasModifiedDays ago
    Filter(
        case dateType:
        of AttributeChange:
            @["-ctime", num.string]
        of Modification:
            @["-mtime", num.string]
        of Access:
            @["-atime", num.string]
    )

proc fileTypToArg(fileType: FileType): string =
    case fileType:
    of File:
        "f"
    of Directory:
        "d"
    of SymLink:
        "l"
    of Char:
        "c"
    of NamedPipe:
        "p"
    of Block:
        "b"
    of Socket:
        "s"

proc toSeqString(filters: seq[Filter]): seq[string] =
    cast[seq[seq[string]]](filters).flatten()