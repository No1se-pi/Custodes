from dotenv import find_dotenv

lang_custodes = {
"eng": f"""
Commit blocked by Custodes.
Stop words detected in the last commit index.
You can find the full list of words in the .env file {find_dotenv()}
""",

"ru": f"""
Коммит заблокирован Наблюдателем.
Стоп слова обнаружены в последнем индексе коммита.
Вы можете ознакомится с полным списком слов в файле .env {find_dotenv()}
"""
}

logo_custodes = r"""
   |\                 /|
   | \               / |
   |愛\     /\      /静|
   |  /    /  \     \  |
   | /    / /\ \     \ |
   |/    / /()\ \     \|
   |\   / /____\ \    /|
   | \ /________\ \  / |
   |  /___________ \   |
"""