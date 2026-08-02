# Архитектура Custodes

Этот документ объясняет не только «где какой файл», но и почему границы
проведены именно так. Его цель — сделать проект пригодным для самостоятельного
развития без возвращения к одному огромному shell-скрипту.

## Карта проекта

```text
custodes.sh                 тонкий CLI dispatcher
├── lib/bootstrap.sh        порядок подключения модулей
├── lib/core.sh             пути, версия, общие проверки
├── lib/config.sh           безопасное чтение/изменение .env
├── lib/ui.sh               цветной вывод и UI-примитивы
├── lib/i18n.sh             выбор локали
├── locales/en.sh           английские сообщения
├── locales/ru.sh           русские сообщения
└── lib/commands/
    ├── repository.sh       hook и pipeline check
    ├── sonar.sh            Sonar server/scanner
    ├── settings.sh         настройки и интерактивное меню
    └── system.sh           status/update/uninstall/help

parser.py                   совместимая Python entrypoint
└── custodes/
    ├── config.py           typed settings
    ├── git_diff.py         staged files и добавленные строки
    ├── entropy.py          извлечение кандидатов и Shannon entropy
    ├── scanner.py          правила и Finding
    └── cli.py              вывод результатов и exit codes

installer.sh                Linux/Git Bash installer
install.ps1                 Windows installer
sonar-project.properties    анализ исходников Custodes
tests/                      реальные Git integration tests
```

## Почему Bash и Python разделены

Bash хорошо подходит для оркестрации внешних программ: Git, Docker,
SonarScanner, установки hook. Но разбор diff, вычисление энтропии, дедупликация
findings и тестирование проще и надёжнее в Python.

Поэтому правило такое:

- Bash отвечает за **что и в каком порядке запустить**;
- Python отвечает за **что считать нарушением**;
- `custodes.sh` не содержит предметной логики вообще.

## Pipeline pre-commit

`cmd_init` создаёт hook с маркером `Managed by Custodes`. Маркер позволяет
удалить именно наш hook и не затронуть пользовательский.

Hook вызывает `custodes check`:

1. `run_secret_scan` находит Python из установленного или development venv.
2. `parser.py` загружает `custodes.cli`.
3. `git_diff.py` читает staged paths через NUL-разделитель.
4. Для каждого файла разбираются только строки `+` внутри diff hunks.
5. `scanner.py` применяет banwords и entropy detection.
6. При findings Python возвращает `1`, и Sonar не запускается.
7. При чистом результате `repository.sh` проверяет настройку Sonar.
8. `sonar.sh` запускает Docker/native scanner и ждёт Quality Gate.

## Exit codes

| Код | Значение |
|---:|---|
| `0` | проверка пройдена |
| `1` | найден секрет либо Quality Gate не пройден |
| `2` | инфраструктурная ошибка: Git, Python, Docker, config, Sonar |

Pre-commit блокируется при любом ненулевом коде. Исключение: если
`CUSTODES_SONAR_BLOCK_ON_FAILURE=no`, ошибка Sonar превращается в warning, но
ошибка secret scanner всегда остаётся блокирующей.

## Конфигурация и безопасность

Конфиг нельзя подключать командой `source .env`: тогда любая строка вида
`VALUE=$(dangerous-command)` стала бы исполняемым кодом. `lib/config.sh` читает
его как пары key/value, а изменение разрешено только для whitelist ключей.

Python также не ищет ближайший `.env`. Иначе `.env` проверяемого проекта мог бы
подменить настройки Custodes. Путь передаётся через `CUSTODES_CONFIG`.

Исключения путей объединяются из пользовательского `CUSTODES_EXCLUDE_PATHS` и
versioned `.custodesignore`. Это осознанный allowlist для fixtures/generated
content; изменение `.custodesignore` должно проверяться так же внимательно, как
изменение правил scanner.

Sonar token:

- хранится в пользовательском ignored config;
- маскируется в UI;
- вводится через `read -s`;
- передаётся scanner-у через environment, а не аргумент командной строки.

## Staged diff

Сканировать рабочий файл целиком неправильно: commit может содержать только
часть его изменений. Custodes получает содержимое из `git diff --cached` и
проверяет только добавленные строки.

`--name-only -z` нужен для имён с пробелами и необычными символами.
`--diff-filter=ACMR` исключает удалённые файлы. Бинарные diff без добавленных
текстовых строк автоматически пропускаются.

## Энтропия

`entropy.py` разделён на два этапа:

1. `entropy_candidates` извлекает длинные secret-like токены;
2. `shannon_entropy` вычисляет значение для каждого кандидата.

Фильтрация до вычисления важна: энтропия обычной длинной строки или пути сама
по себе не доказывает наличие секрета. Placeholder markers и минимальное
разнообразие символов снижают шум, но полностью false positives не устраняют.

## SonarQube на Windows

SonarQube server работает в существующем контейнере `sonarqube`. Scanner
запускается отдельным официальным контейнером. Для связи с host используется
`host.docker.internal`; на Linux добавляется `host-gateway`.

Git Bash преобразует Windows paths перед вызовом Docker, поэтому команда
устанавливает `MSYS_NO_PATHCONV=1` и передаёт пути, полученные через `pwd -W`.

## Как добавлять новую команду

1. Выберите подходящий файл в `lib/commands` или создайте новый модуль.
2. Добавьте функцию `cmd_<name>`.
3. Подключите модуль в `lib/bootstrap.sh`.
4. Добавьте только одну строку маршрутизации в `custodes.sh`.
5. Добавьте тексты обеих локалей, если команда выводит пользовательские фразы.
6. Обновите help и README.
7. Выполните Python tests, `bash -n` и ShellCheck.

Не возвращайте большие тексты или реализацию команды в `custodes.sh`: он должен
оставаться обозримым на одном экране.

## Как добавлять правило сканера

1. Представьте результат как `Finding`, а не печатайте внутри правила.
2. Добавьте чистую функцию в отдельный Python-модуль.
3. Подключите её в `scanner.py`.
4. Не выводите найденный secret без учёта `reveal_values`.
5. Добавьте positive и negative test на реальном staged diff.

Такой подход сохраняет разделение: detection ничего не знает о цветах CLI,
Docker и hook, а shell ничего не знает о внутреннем устройстве энтропии.
