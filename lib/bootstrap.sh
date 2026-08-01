#!/usr/bin/env bash

# Единственная точка сборки shell-модулей. Порядок source важен: команды
# используют функции конфигурации, локализации и UI, объявленные выше.
# shellcheck disable=SC1091 # Путь вычисляется относительно установленного файла.
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/core.sh"
source "${CUSTODES_ROOT}/lib/config.sh"
ensure_config || { printf 'Custodes: cannot create %s\n' "$CUSTODES_CONFIG" >&2; exit 2; }
load_language
source "${CUSTODES_ROOT}/locales/en.sh"
source "${CUSTODES_ROOT}/locales/ru.sh"
source "${CUSTODES_ROOT}/lib/i18n.sh"
source "${CUSTODES_ROOT}/lib/ui.sh"
source "${CUSTODES_ROOT}/lib/commands/repository.sh"
source "${CUSTODES_ROOT}/lib/commands/sonar.sh"
source "${CUSTODES_ROOT}/lib/commands/settings.sh"
source "${CUSTODES_ROOT}/lib/commands/system.sh"
