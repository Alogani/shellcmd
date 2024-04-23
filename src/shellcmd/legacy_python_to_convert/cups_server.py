#!/usr/bin/python3

# Normally already installed, up and running
PROPERTIES = { "services": [ "cups" ] }

from ChrootHandler import ch_run, ch_Path

config = ch_Path("/etc/cups/cupsd.conf")

def add_listening(port: int):
    config_all_lines = config.open("r").readlines()
    i=0
    listen_statement_found=False
    for config_line in config_all_lines:
        # Write after all listen statements
        if config_line.startwith("Listen"):
            listen_statement_found = True
        elif listen_statement_found:
            config_all_lines.insert(i+1, f"Port {port}")
            break
        i += 1
    config.open("w").writelines(config_all_lines)
    ch_run(["systemctl", "restart"] + services.split())
    
