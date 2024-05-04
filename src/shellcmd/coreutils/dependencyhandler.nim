import ./[common, distro, package]

type DependencyTree = ref object
    linux*: seq[string]
    debian*: seq[string]
    fedora*: seq[string]
    archlinux*: seq[string]

var DependencyPackages*: DependencyTree

if DependencyPackages == nil:
    DependencyPackages = DependencyTree()

proc installAllDependencies*(sh: ProcArgs): Future[void] {.async.} =
    let allPackages = DependencyPackages.linux & (
        case await sh.getDistroName():
        of Debian:
            DependencyPackages.debian
        of Fedora:
            DependencyPackages.fedora
        of ArchLinux:
            DependencyPackages.archlinux)
    await sh.installWithoutEnabling(allPackages)