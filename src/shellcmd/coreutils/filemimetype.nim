import ./[common]

type
    FileMimeType* = enum
        Application = "application", Audio = "audio"
        Example = "example", Font = "font"
        Image = "image", Message = "message"
        Model = "model", Multipart = "multipart"
        Text = "text", Video = "video"

    FileMimeSubType* = enum
        UnknownMimeType = "unknown?"
        Pdf = "acrobat|pdf"
        ZstdCompression = "zstd"


proc getFileMimeType*(sh: ProcArgs, path: Path): Future[(FileMimeType, FileMimeSubType, string)] {.async.} =
    let envModifier = {"LANG": "US"}.toTable()
    let
        fulltype = await(sh.runGetOutput(@["file", "-b", "--mime-type", $path], internalCmd.merge(
            envModifier = some envModifier))
        ).split("/", maxsplit = 1)
        maintype = fulltype[0]
        subtype = fulltype[1]
    for mimetype in FileMimeType:
        if maintype == $mimetype :
            result[0] = mimetype
            break
    result[1] = UnknownMimeType
    for mimetype in FileMimeSubType:
        for mimetypeMatches in ($mimetype).split("|"):
            if mimetypeMatches.startsWith(subtype):
                result[1] = mimetype
                break
    result[2] = subtype