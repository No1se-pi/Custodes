#!/usr/bin/env python3

import subprocess
import os
from dotenv import load_dotenv, find_dotenv
import sys

from messeges import *

#______variables and settings______
load_dotenv() #loading env
banwords = os.getenv("banwords")

if banwords is not None and len(banwords) > 0: #Protection against missing parameters
    banwords = [word.strip() for word in banwords.split(",") if word.strip()] #list of all banned words

else:
    sys.exit(f"There are no arguments in the \"banwords\" \nvariable .env — {find_dotenv() or "~/.local/share/custodes/"}") #Returning an error message

strict_compliance = lang_custodes[os.getenv("lang_custodes", "eng")]

#______the basic logic______

#Allows you to get all the modified files added to the index.
def get_modified_file(): 
    
    modified_files=[]

    process = subprocess.Popen(
        ["git","diff","--cached","--name-only"],
        stdout=subprocess.PIPE,
        text = True
    )

    for line in process.stdout:
        modified_files.append(line[:-1])

    return modified_files

#Scans files in the index for secrets
def parsing_current_file(current_file):
    blocked_lines = [] #list of all "dangerous" lines
    global flag_secret

    process = subprocess.Popen(
        ["git","diff","--cached", current_file],
        stdout=subprocess.PIPE,
        text=True
    )

    for line in process.stdout:
        for ban_word in banwords:

            if ban_word in line and line[0] == "+" and line[0:3] != "+++":
                blocked_lines.append(line)

    return blocked_lines

#______start______
def main():
    modified_files=get_modified_file()
    global flag_secret

    output_violations = dict()

    if len(modified_files) > 0:


        for current_file in modified_files:
            violations = parsing_current_file(current_file)
            if len(violations) > 0:
                output_violations[current_file] = violations

        if len(output_violations) > 0:
            if os.getenv("logo_custodes") == "yes":
                print(logo_custodes)
            print(strict_compliance)

            if os.getenv("output_violations") == "yes":
                for current_file in output_violations:
                    print(current_file,":\n",sep="")
                    print(*output_violations[current_file], sep="",end="_____________________________________\n\n")
                print("end")

            sys.exit(1)

        else:
            sys.exit()

    else:
        sys.exit()

main()