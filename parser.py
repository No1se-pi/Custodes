import subprocess
import os
from dotenv import load_dotenv

load_dotenv()
banwords = os.getenv("banwords").split(",")

process = subprocess.Popen(
    ["git","diff","--staged"],
    stdout=subprocess.PIPE,
    text=True
)

for line in process.stdout:
    for ban_word in banwords:
        if ban_word in line and line[0] == "+":
            print(line)
            print(
                '''
ALLERT SUKA BOY!!!
DONT PUSH MAFAKA BITCH
                '''
            )