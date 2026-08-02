# Changelog

Заметные изменения Custodes документируются здесь. Версии следуют
[Semantic Versioning](https://semver.org/).

## 1.1.0 — 2026-08-02

### Добавлено

- entropy detection для случайных токенов и ключей;
- SonarQube scan и блокирующий Quality Gate после успешного secret scan;
- интерактивные `custodes settings` и `custodes sonar ...`;
- установщик PowerShell и поддержка Windows/Git Bash, включая кириллический
  путь профиля пользователя;
- безопасное скрытие значений находок и versioned `.custodesignore`;
- Python, shell integration и coverage tests.

### Изменено

- монолитный `custodes.sh` разделён на `lib/commands`, UI, config, i18n и
  локали;
- Python-сканер разделён на config, Git diff, entropy, findings и CLI;
- сайт, README, Wiki и архитектурная документация обновлены для v1.1.0.

### Исправлено

- Docker SonarScanner больше не получает относительный
  `sonar.scanner.metadataFilePath`, который ломал анализ на Windows;
- launcher корректно работает, когда Windows profile path содержит кириллицу.

## 1.0.0

- первый стабильный релиз: staged secret scan, pre-commit hook, локализация и
  базовые команды установки/обновления.
