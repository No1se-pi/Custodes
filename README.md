# Version 1.1.0

<p align="center">
  <img src="https://no1se-pi.github.io/Custodes/assets/custodes-hero-mark.svg" alt="Custodes logo" width="180">
</p>

<h1 align="center">Custodes</h1>

<p align="center">
  Локальный pre-commit security pipeline: стоп-слова, энтропия и SonarQube Quality Gate.
</p>

<p align="center">
  <a href="https://no1se-pi.github.io/Custodes/">Лендинг</a> ·
  <a href="https://github.com/No1se-pi/Custodes">GitHub</a> ·
  <a href="docs/ARCHITECTURE.md">Архитектура</a>
</p>

---

## Что делает Custodes

Custodes проверяет изменения, добавленные в Git index через `git add`, до
создания коммита. Проверка состоит из последовательных этапов:

```text
git commit
  ↓
managed pre-commit hook
  ↓
стоп-слова + высокоэнтропийные токены
  ├─ нарушение → exit 1 → commit заблокирован
  ↓
SonarQube (если включён)
  ├─ scanner/Quality Gate failed → commit блокируется по настройке
  ↓
commit разрешён
```

SonarQube никогда не запускается, если проверка секретов уже нашла нарушение.
Это экономит время и не отправляет подозрительный код на анализ.

Custodes — учебный pet-project и дополнительный локальный барьер. Он не заменяет
Gitleaks, TruffleHog, серверный CI и правила защиты веток.

## Возможности

- поиск пользовательских стоп-слов без учёта регистра;
- entropy detection для случайных API-токенов и ключей;
- проверка только добавленных строк staged diff;
- корректная работа с пробелами в именах файлов;
- безопасный вывод: найденные значения по умолчанию скрываются;
- опциональный SonarQube после успешного secret scan;
- ожидание Quality Gate с возможностью блокировки коммита;
- Docker и native режимы SonarScanner;
- интерактивные настройки и цветной CLI;
- Linux и Windows Git Bash;
- безопасное обновление из стабильной ветки `release`.

## Ветки репозитория

| Ветка | Назначение |
|---|---|
| `dev` | разработка новых возможностей |
| `main` | проверенный исходный код проекта |
| `release` | стабильные файлы, которые получает `custodes update` |
| `gh-pages` | только `index.html` и `assets/` лендинга |

GitHub Pages нужно настроить на `gh-pages` и `/(root)` в
`Settings → Pages → Deploy from a branch`.

## Установка на Windows

Требования:

- Windows 10/11;
- Python 3;
- Git for Windows с Git Bash;
- Docker Desktop — только для Docker-режима SonarScanner/SonarQube.

В PowerShell:

```powershell
git clone https://github.com/No1se-pi/Custodes.git
cd Custodes
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Установщик:

- находит Git Bash даже при нестандартном пути установки;
- копирует Custodes в `%USERPROFILE%\.local\share\custodes`;
- создаёт отдельный Python venv;
- создаёт `%USERPROFILE%\.local\bin\custodes.cmd`;
- добавляет каталог команды в пользовательский `PATH`;
- не перезаписывает существующий `.env`.

После установки откройте новый терминал:

```powershell
custodes help
```

## Установка на Linux

Требуются Git, Bash и Python 3 с модулем `venv`.

```bash
git clone https://github.com/No1se-pi/Custodes.git
cd Custodes
bash installer.sh
```

Если команда не найдена, добавьте `~/.local/bin` в `PATH`.

## Быстрый старт

Внутри нужного репозитория:

```bash
custodes init
custodes settings
```

После этого обычный commit автоматически вызывает pipeline:

```bash
git add .
git commit -m "my change"
```

Custodes не перезаписывает чужой `pre-commit` hook. Удаляется только hook с
маркером `Managed by Custodes`.

## Команды

```text
custodes                         интерактивное меню
custodes help                    справка
custodes init                    установить hook
custodes check                   secrets → entropy → optional SonarQube
custodes check --no-sonar        выполнить только локальную проверку секретов
custodes status                  состояние hook и анализаторов
custodes settings                интерактивные настройки
custodes settings show           показать настройки с замаскированным токеном
custodes settings set KEY VALUE  изменить один разрешённый параметр
custodes sonar status            состояние сервера
custodes sonar start             запустить существующий container `sonarqube`
custodes sonar scan              запустить анализ проекта вручную
custodes sonar logs              последние логи контейнера
custodes remove                  удалить hook текущего репозитория
custodes update                  обновиться из ветки release
custodes uninstall               удалить установленный Custodes
```

## Настройки

Пользовательский конфиг находится в:

```text
~/.local/share/custodes/.env
```

Шаблон: [`config/custodes.env.example`](config/custodes.env.example).

Основные параметры:

| Переменная | Default | Назначение |
|---|---:|---|
| `CUSTODES_LANG` | `eng` | `eng` или `ru` |
| `CUSTODES_BANWORDS` | встроенный список | правила через запятую |
| `CUSTODES_EXCLUDE_PATHS` | venv и dependencies | glob-паттерны через запятую |
| `CUSTODES_ENTROPY_ENABLED` | `yes` | включить entropy detection |
| `CUSTODES_ENTROPY_THRESHOLD` | `4.0` | минимальная энтропия токена |
| `CUSTODES_ENTROPY_MIN_LENGTH` | `20` | минимальная длина кандидата |
| `CUSTODES_REVEAL_VALUES` | `no` | показывать потенциальный секрет в терминале |
| `CUSTODES_SONAR_ENABLED` | `no` | запускать Sonar после secret scan |
| `CUSTODES_SONAR_MODE` | `docker` | `docker` или `native` |
| `CUSTODES_SONAR_BLOCK_ON_FAILURE` | `yes` | блокировать commit при ошибке/Quality Gate |

Старые имена `banwords`, `entropy`, `lang_custodes`, `logo_custodes` и
`output_violations` читаются для обратной совместимости.

Дополнительные project-specific исключения можно хранить в `.custodesignore`,
по одному glob-паттерну на строку. Используйте их только для синтетических
fixtures, generated files и документации: такой файл является частью security
review и не должен скрывать обычные исходники.

### Почему значения секретов скрыты

Security scanner не должен сам копировать найденный API-ключ в terminal log.
Поэтому вывод выглядит примерно так:

```text
settings.py:12  high entropy 4.63 >=4.00
  API_TOKEN=<redacted>
```

Показывать строку целиком можно через `CUSTODES_REVEAL_VALUES=yes`, но это менее
безопасный режим.

## Интеграция SonarQube

Custodes рассчитан на уже запущенный локальный SonarQube. Для контейнера с
именем `sonarqube` доступны:

```bash
custodes sonar start
custodes sonar status
```

1. Откройте `http://localhost:9000`.
2. Создайте token: `My Account → Security → Generate Tokens`.
3. Запустите `custodes settings`.
4. Вставьте token в пункт `Sonar token` — ввод скрывается.
5. Включите `SonarQube`.

Не используйте пароль аккаунта в конфиге. Custodes передаёт token scanner-у
только через переменную окружения `SONAR_TOKEN` и не печатает его в командной
строке.

Настройки проекта лежат в [`sonar-project.properties`](sonar-project.properties).
В Docker-режиме официальный образ SonarScanner монтирует текущий Git repository
read-only по смыслу анализа, а служебный результат пишет в игнорируемую `.sonar`.

`sonar.qualitygate.wait=true` заставляет scanner дождаться Quality Gate. Если
gate не пройден, scanner возвращает ненулевой exit code и commit блокируется при
`CUSTODES_SONAR_BLOCK_ON_FAILURE=yes`.

Важно: полный Sonar-анализ на каждый commit может быть медленным. Его можно
отключить и запускать вручную через `custodes sonar scan`, оставив быстрый
secret scan в hook.

## Entropy detection

Энтропия не пытается понять назначение переменной. Она ищет длинные токены с
разнообразным набором символов и вычисляет Shannon entropy в битах на символ.

Для снижения ложных срабатываний:

- проверяются только добавленные строки;
- default minimum length равен 20;
- отбрасываются повторяющиеся значения и явные placeholder-строки;
- порог ограничен безопасным диапазоном `2.5..8.0`;
- секреты не выводятся целиком.

Если проект содержит много сгенерированных идентификаторов, поднимите threshold
или minimum length через `custodes settings`.

## Разработка и тесты

На Windows команды выполняются именно через Git Bash:

```bash
./venv/Scripts/python.exe -m pip install -r requirements-dev.txt
./venv/Scripts/python.exe -m unittest discover -s tests -v
./venv/Scripts/python.exe -m compileall -q parser.py custodes
./venv/Scripts/python.exe -m ruff check custodes parser.py tests
./venv/Scripts/python.exe -m ruff format --check custodes parser.py tests
find lib locales -name '*.sh' -print0 | xargs -0 bash -n
bash ./tests/test_cli.sh
```

Тесты создают временные Git-репозитории и проверяют реальный staged diff:
стоп-слова, entropy-only блокировку, удалённые строки и имена с пробелами.

Подробное устройство проекта и правила изменения модулей описаны в
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Ограничения

- `git commit --no-verify` обходит локальный hook;
- entropy detection остаётся эвристикой и может давать false positive;
- SonarQube требует доступный server и отдельный token;
- Docker-режим впервые загружает образ SonarScanner и анализаторы;
- локальный hook не заменяет проверку в защищённом серверном CI.

## Автор

Yaroslav Boikov / No1se

GitHub: <https://github.com/No1se-pi/Custodes>

Website: <https://no1se-pi.github.io/Custodes/>

Custodes создан как учебный проект для практики Git, Bash, Python и DevSecOps.
