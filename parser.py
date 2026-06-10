import subprocess

process = subprocess.Popen(
    ["git","diff","--staged"],
    stdout=subprocess.PIPE,
    text=True
)

for line in process.stdout:
    print(line.strip())

