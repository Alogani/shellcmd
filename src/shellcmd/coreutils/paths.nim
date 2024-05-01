import std/paths
import asyncproc

export paths except absolutePath, getCurrentDir


const EmptyPath* = Path("")

func `$`*(path: Path): string =
    string(path)

converter toFutPath*(futPath: Future[string]): Future[Path] =
    cast[Future[Path]](futPath)

converter toPath*(path: string): Path =
    Path(path)

converter toSeqPath*(path: seq[string]): seq[Path] =
    cast[seq[Path]](path)

converter toString*(path: Path): string =
    $path

converter toSeqString*(path: seq[Path]): seq[string] =
    cast[seq[string]](path)

proc getCurrentDir*(sh: ProcArgs): Future[Path] =
    sh.runGetOutput(@["pwd"], internalCmd)

proc absolutePath*(sh: ProcArgs, path: Path): Future[Path] {.async.} =
    absolutePath(path, await sh.getCurrentDir())

func absolutePath*(path: Path; root: Path): Path =
    paths.absolutePath(path, root)
