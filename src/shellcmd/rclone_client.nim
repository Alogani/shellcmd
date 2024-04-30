import ./coreutils
import ./private/dependencyhandler


DependencyPackages.linux.add("rclone")


proc mount*(sh: ProcArgs, profileFile, mountpoint: Path, remoteName = ""): Future[void] =
    let remoteName =
        if remoteName == "":
            profileFile.splitFile.name
        else:
            remoteName
    # Could also popen with start_new_session=True
    sh.runDiscard(@["rclone", "--daemon", "--config=" & profileFile, "mount",
        "--vfs-cache-mode", "writes", "--allow-non-empty", "--allow-other",
        remoteName & ":/", mountpoint])
        

#[
gpg_key_id="FBF737ECE9F8AB18604BD2AC93935E02FF3B54FA"

def update():
    if ch_run(["rclone", "selfupdate"]).returncode == 0 and ch_run(["rclone", "version"]).returncode == 0:
        return

    last_version = requests.get("https://downloads.rclone.org/version.txt").text
    current_version = ch_run(["rclone", "version"], capture_output=True).stdout.decode().splitlines()[0]
    if last_version == current_version:
        return

    with InTempDir():
        last_version_short = last_version.replace("rclone ", "").replace("\n", "")
        ch_run(["rclone", "copy", "--http-url", f"https://downloads.rclone.org/{last_version_short}", ":http:SHA256SUMS", "."])
        ch_run(["rclone", "copy", "--http-url", f"https://downloads.rclone.org/{last_version_short}", ":http:rclone-{last_version_short}-linux-amd64.deb", "."])
    
        gpg.import_key(gpg_key_id)
        if not (gpg.verify("SHA256SUMS") and checksum.verify_file("sha256sums", "SHA256SUMS")):
            return
    
        ch_run(["dpkg", "-i", f"rclone-{last_version_short}-linux-amd64.deb"])

]#