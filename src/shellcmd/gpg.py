#!/usr/bin/python3

from mytoolbox.subprocess2 import run
from pathlib import Path

key_servers = ["keys.openpgp.org", "keyserver.ubuntu.com"]

def import_key(key_id: str, key_server: str = ""):
    return not run(["gpg", f"--keyserver {url}" if key_server else "",
    "--receive-keys", key_id]).returncode

def verify(file_path: str):
    return not run(["gpg", "--verify", file_path]).returncode

def _allow_pinentry_passphrase():
    gpg_agent_conf = Path.home().joinpath(".gnupg/gpg-agent.conf")
    if not gpg_agent_conf.parent.exists():
        gpg_agent_conf.parent.mkdir()
    else:
        for line in gpg_agent_conf.open("r").readlines():
            if line.startswith("allow-loopback-pinentry"):
                return
    gpg_agent_conf.open("a").write("allow-loopback-pinentry\n")

def encrypt_symmetric(source: str, destination: str, password: str, algorithm="AES256", erase=False):
    _allow_pinentry_passphrase()
    exit_code = run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase-fd", "0",
        "--symmetric", "--cipher-algo", algorithm,
        "--output", destination,  source], input=password.encode()).returncode
    if exit_code == 0  and erase:
        Path(source).unlink()
    return exit_code

def decrypt_symmetric(source: str, destination: str, password: str, erase=False):
    _allow_pinentry_passphrase()
    exit_code = run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase-fd", "0",
        "--decrypt",
        "--output", destination, source], input=password.encode()).returncode
    if exit_code == 0 and erase:
        Path(source).unlink()
    return exit_code

