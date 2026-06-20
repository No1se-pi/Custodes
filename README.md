# Version 0.2

<p align="center">
  <img src="https://no1se-pi.github.io/Custodes/assets/custodes-hero-mark.svg" alt="Custodes logo" width="180">
</p>

<h1 align="center">Custodes</h1>

<p align="center">
  Минимальный CLI-инструмент, который помогает не закоммитить секреты в Git-репозиторий.
</p>

<p align="center">
  <a href="https://no1se-pi.github.io/Custodes/">
    <img src="https://img.shields.io/badge/Open%20landing-Custodes-6C3DFF?style=for-the-badge" alt="Open Custodes landing">
  </a>
</p>

<p align="center">
  <a href="https://no1se-pi.github.io/Custodes/">🌐 Лендинг проекта</a>
  ·
  <a href="https://github.com/No1se-pi/Custodes">GitHub repository</a>
</p>

---

## Что это за программа?

**Custodes** — это небольшой локальный инструмент безопасности для разработчика.

Главная задача Custodes — проверять staged-изменения перед коммитом и блокировать commit, если в нём найдены потенциальные секреты: API-ключи, токены, пароли, приватные ключи или другие запрещённые строки из конфигурации.

Custodes не пытается заменить полноценные инструменты вроде Gitleaks или TruffleHog. Это учебный и расширяемый pet-project, который выполняет одну конкретную задачу: **не дать случайно отправить секреты в репозиторий**.

---

## Как это работает?

После установки Custodes создаёт `pre-commit` hook в Git-репозитории.

Цепочка работы выглядит так:

```text
git commit
    ↓
.git/hooks/pre-commit
    ↓
custodes check
    ↓
сканирование staged-файлов
    ↓
секрет найден → commit блокируется
секретов нет → commit проходит
```

Custodes проверяет именно **staged changes**, то есть изменения, добавленные через:

```bash
git add <file>
```

---

## Возможности

На текущий момент Custodes умеет:

- устанавливать `pre-commit` hook в текущий Git-репозиторий;
- проверять staged-файлы перед коммитом;
- искать запрещённые слова и паттерны из `.env`;
- блокировать commit через exit code `1`;
- выводить список файлов и строк, где были найдены нарушения;
- показывать статус установленной версии;
- открывать конфиг для редактирования;
- удалять Custodes из системы;
- обновляться из репозитория проекта.

---

## Установка

> Сейчас Custodes ориентирован в первую очередь на Linux / Kali / Debian-like системы.

Склонируйте репозиторий:

```bash
git clone https://github.com/No1se-pi/Custodes.git
cd Custodes
```

Запустите установщик:

```bash
bash installer.sh
```

После установки проверьте, что команда доступна:

```bash
custodes help
```

Если команда не найдена, проверьте, что `~/.local/bin` есть в переменной `PATH`.

---

## Быстрый старт

Перейдите в нужный Git-репозиторий:

```bash
cd my-project
```

Установите hook:

```bash
custodes init
```

Теперь при обычном коммите Custodes будет запускаться автоматически:

```bash
git add .
git commit -m "test commit"
```

Если в staged-изменениях есть секрет, commit будет заблокирован.

---

## Команды

```bash
custodes help
```

Показать справку.

```bash
custodes init
```

Установить `pre-commit` hook в текущий Git-репозиторий.

```bash
custodes check
```

Вручную проверить staged-файлы на наличие секретов.

```bash
custodes status
```

Проверить текущую установленную версию Custodes и наличие обновлений.

```bash
custodes update
```

Обновить файлы Custodes из GitHub-репозитория.

```bash
custodes config
```

Открыть конфигурационный файл `.env`.

```bash
custodes uninstall
```

Удалить Custodes из системы.

```bash
custodes about
```

Показать информацию о проекте.

---

## Пример `.env`

### Зачем нужен `.env`?

`.env` хранит настройки Custodes:

- список запрещённых слов;
- нужно ли показывать логотип при блокировке;
- нужно ли выводить конкретные строки с нарушениями;
- язык сообщений.

### Пример заполнения

```bash
banwords=SSH_KEY,API_KEY,password,hash

logo_custodes=yes # values: yes; any other value means no

output_violations=yes # values: yes; any other value means no

lang_custodes=ru # values: eng, ru
```

### Доступные параметры

#### `banwords`

Список запрещённых слов через запятую.

Пример:

```bash
banwords=SSH_KEY,API_KEY,password,token
```

Если в добавленных строках будет найдено одно из этих значений, commit будет заблокирован.

#### `logo_custodes`

Включает или отключает отображение ASCII-логотипа при блокировке.

```bash
logo_custodes=yes
```

Любое значение, отличное от `yes`, считается выключенным.

#### `output_violations`

Управляет выводом конкретных строк, где были найдены нарушения.

```bash
output_violations=yes
```

Любое значение, отличное от `yes`, считается выключенным.

#### `lang_custodes`

Язык сообщений Custodes.

```bash
lang_custodes=ru
```

Доступные значения:

```text
ru  — русский язык
eng — английский язык
```

---

## Пример блокировки

Допустим, в файл добавлена строка:

```bash
API_KEY=12345
```

После:

```bash
git add .
git commit -m "add config"
```

Custodes найдёт запрещённое слово `API_KEY` и остановит commit.

---

## Важные ограничения

Custodes — это локальная защита на уровне Git hook, поэтому есть ограничения:

- `git commit --no-verify` может обойти `pre-commit` hook;
- инструмент пока не является заменой полноценным secret-scanner решениям;
- текущая версия ориентирована на Linux;
- правила поиска пока простые и основаны на списке `banwords`;
- возможны ложные срабатывания.

---

## Roadmap

Планируемые улучшения:

- более точная работа с Git diff;
- вывод номеров строк;
- regex-правила для токенов, приватных ключей и API-ключей;
- entropy detection для случайных секретов;
- allowlist для файлов и значений;
- более аккуратный update/uninstall;
- Windows-версия;
- сборка в единый исполняемый файл.

---

## Автор

Project by **Yaroslav Boikov / No1se**.

GitHub: <https://github.com/No1se-pi/Custodes>

Website: <https://no1se-pi.github.io/Custodes/>

---

## Дисклеймер

Custodes создан как pet-project и учебный инструмент для практики Git, Bash, Python и DevSecOps-подходов.

Используйте его аккуратно и проверяйте конфигурацию перед применением в важных репозиториях.
