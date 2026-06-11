import subprocess
import os
from dotenv import load_dotenv, find_dotenv
import sys

from messeges import *

#______variables and settings______
load_dotenv() #loading env

if len(os.getenv("banwords")) > 0: #Protection against missing parameters
    banwords = [word.strip() for word in os.getenv("banwords").split(",")] #list of all banned words
else:
    sys.exit(f"There are no arguments in the \"banwords\" \nvariable .env — {find_dotenv()}") #Returning an error message

strict_compliance = lang_custodes[os.getenv("lang_custodes", "eng")]
flag_secret = False

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
                flag_secret = True

    return blocked_lines

#______start______
def main():
    modified_files=get_modified_file()
    global flag_secret

    if len(modified_files) > 0:


        if os.getenv("logo_custodes") == "yes":
            print(logo_custodes)
        print(strict_compliance)

        for current_file in modified_files:
            print(current_file,":",end="\n\n")
            print(*parsing_current_file(current_file),sep="")
            print("______________")
        print("end")

        if flag_secret == True:
            sys.exit(1)
        else:
            sys.exit()

    else:
        sys.exit()

main()