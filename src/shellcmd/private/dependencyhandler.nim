type DependencyTree = ref object
    linux*: seq[string]
    debian*: seq[string]
    fedora*: seq[string]

var DependencyPackages*: DependencyTree

if DependencyPackages == nil:
    DependencyPackages = DependencyTree()