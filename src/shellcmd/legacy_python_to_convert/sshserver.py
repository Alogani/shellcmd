import ./coreutils
import ./private/dependencyhandler

const SshService* = "ssh"

DependencyPackages.linux.add("openssh-server")


## Replace services by startServer

def symlink_config(config_path: str):
    for file in Path(config_path).iterdir():
        ch_Path("/etc/ssh/sshd_config.d").joinpath(file.name).symlink_to(file.absolute())
