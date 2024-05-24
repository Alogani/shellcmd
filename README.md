# ShellCmd
Collection of asynchronous Terminal commands to be used inside nim.

**Important note: A major refactor is upcomming to get rid of async/await syntax by changing the underlying IO library**

## Features

- Developped with interactivness in mind (you can develop both semi-automated script, as well as fully automated one)
- Opiniated exception handling: as default, exception immediatly stop execution, but you can also fallback to a shell and continue where you stopped
- Developped with remote execution in mind: running a command remotly (ssh), on a chrooted system or locally should need to modify only one line of the whole code
- As concise as a shell: Focused to be as one liner as possible even for complex commands and to avoid repetition
- Focused to return as much as possible high level objects instead of raw data (eg : sh.ls(path) -> seq[Path])
- Self documenting: Goal is to make you know how to use any command only by looking at its definition. But a basic knowledge of the commands and especially their names is required (eg: ls, cat, etc.)
- Generalist: Goal is to cover as many terminal tools as possible (As a default export if their are shipped very common, or needing an import if their need to be installed or are less common), and to cover 90% of uses cases of those tools (all uses cases coverage is not possible nor wanted, if your case is too specific, use [asyncproc](https://github.com/Alogani/asyncproc))
- Easy to extend: thanks to the use of the powerful library [asyncproc](https://github.com/Alogani/asyncproc) and its flexible streams manipulation [asyncio](https://github.com/Alogani/asyncio)

## Getting started

### Installation

`nimble install shellcmd`

### Example usage

You can see [shellcmd-examples](https://github.com/Alogani/shellcmd-examples) to see some usage

### To go further

Source files should be well organized, and it should be easy to understand what each command does and how only by looking into the source file.

## Before using it
- Young API: usage of some tools are susceptible to change. Releases with breaking change will make the second number of semver be updated (eg: v0.1.1 to v0.2.0). For sensitive script, it is advised to run before inside a virtual machine or a chroot
- Host OS: Only available in unix. Support for windows is not in the priority list
- Target OS (eg: ssh): Only unix for now
