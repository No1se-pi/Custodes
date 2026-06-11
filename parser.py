import subprocess
import os
from dotenv import load_dotenv
import sys

from messeges import *

#______variables and settings______
load_dotenv() #loading env
banwords = os.getenv("banwords").split(",") #list of all banned words
strict_compliance = lang_custodes[os.getenv("lang_custodes", "eng")]

blocked_lines = [] #list of all "dangerous" lines

#______the basic logic______
process = subprocess.Popen(
    ["git","diff","--staged"],
    stdout=subprocess.PIPE,
    text=True
)

for line in process.stdout:
    for ban_word in banwords:

        if ban_word in line and line[0] == "+" and line[0:3] != "+++":
            blocked_lines.append(line)

if len(blocked_lines) > 0:
    if os.getenv("logo_custodes") == "yes":
        print(logo_custodes)
    print(strict_compliance)
    print(*blocked_lines, sep="\n")
    sys.exit(1)

sys.exit(0)