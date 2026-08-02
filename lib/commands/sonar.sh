#!/usr/bin/env bash

sonar_project_key() {
    local configured root base properties_key
    configured="$(config_value CUSTODES_SONAR_PROJECT_KEY "")"
    if [[ -n "$configured" ]]; then
        printf '%s\n' "$configured"
        return
    fi
    root="$(git_root)" || return 1
    if [[ -f "${root}/sonar-project.properties" ]]; then
        properties_key="$(awk -F= '/^[[:space:]]*sonar\.projectKey[[:space:]]*=/ {
            value = substr($0, index($0, "=") + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print value
            exit
        }' "${root}/sonar-project.properties")"
        if [[ -n "$properties_key" ]]; then
            printf '%s\n' "$properties_key"
            return
        fi
    fi
    base="$(basename -- "$root")"
    printf '%s' "$base" | tr -c '[:alnum:]_.:-' '-'
    printf '\n'
}

sonar_server_status() {
    local host
    host="$(config_value CUSTODES_SONAR_HOST_URL http://localhost:9000)"
    curl -fsS --max-time 5 "${host%/}/api/system/status" 2>/dev/null
}

docker_mount_path() {
    local path="$1"
    if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
        (cd "$path" && pwd -W)
    else
        (cd "$path" && pwd)
    fi
}

run_sonar_native() {
    local project_key="$1" host="$2" token="$3" wait="$4" timeout="$5"
    command_exists sonar-scanner || {
        ui_error "sonar-scanner is not installed; select docker mode."
        return 2
    }
    SONAR_HOST_URL="$host" SONAR_TOKEN="$token" sonar-scanner \
        "-Dsonar.projectKey=${project_key}" \
        "-Dsonar.qualitygate.wait=${wait}" \
        "-Dsonar.qualitygate.timeout=${timeout}"
}

run_sonar_docker() {
    local project_key="$1" host="$2" token="$3" wait="$4" timeout="$5"
    local repo_root repo_mount cache_dir cache_mount image docker_host
    command_exists docker || { ui_error "Docker CLI not found."; return 2; }
    docker info >/dev/null 2>&1 || { ui_error "Docker Engine is unavailable."; return 2; }

    repo_root="$(git_root)" || return 2
    repo_mount="$(docker_mount_path "$repo_root")" || return 2
    cache_dir="${CUSTODES_HOME}/sonar-cache"
    mkdir -p "$cache_dir" || return 2
    cache_mount="$(docker_mount_path "$cache_dir")" || return 2
    image="$(config_value CUSTODES_SONAR_SCANNER_IMAGE sonarsource/sonar-scanner-cli:latest)"

    # localhost внутри scanner-контейнера указывал бы на сам scanner, а не на
    # Docker Desktop. host.docker.internal одинаково работает на Windows и с
    # добавленным host-gateway на современном Linux Docker.
    docker_host="$host"
    docker_host="${docker_host/\/\/localhost/\/\/host.docker.internal}"
    docker_host="${docker_host/\/\/127.0.0.1/\/\/host.docker.internal}"

    SONAR_HOST_URL="$docker_host" SONAR_TOKEN="$token" MSYS_NO_PATHCONV=1 docker run --rm \
        --add-host host.docker.internal:host-gateway \
        -e SONAR_HOST_URL -e SONAR_TOKEN \
        -v "${repo_mount}:/usr/src" \
        -v "${cache_mount}:/opt/sonar-scanner/.sonar/cache" \
        "$image" \
        "-Dsonar.projectKey=${project_key}" \
        "-Dsonar.qualitygate.wait=${wait}" \
        "-Dsonar.qualitygate.timeout=${timeout}"
}

run_sonar_scan() {
    require_git_repository || { ui_error "$(t not_repo)"; return 2; }
    local mode host token project_key wait timeout
    mode="$(config_value CUSTODES_SONAR_MODE docker)"
    host="$(config_value CUSTODES_SONAR_HOST_URL http://localhost:9000)"
    token="${SONAR_TOKEN:-$(config_value CUSTODES_SONAR_TOKEN "")}"
    project_key="$(sonar_project_key)" || return 2
    wait="$(config_value CUSTODES_SONAR_QUALITY_GATE_WAIT yes)"
    timeout="$(config_value CUSTODES_SONAR_QUALITY_GATE_TIMEOUT 300)"

    if [[ -z "$token" ]]; then
        ui_error "SONAR_TOKEN is empty. Run: custodes settings"
        return 2
    fi
    if is_true "$wait"; then wait="true"; else wait="false"; fi
    sonar_server_status >/dev/null || {
        ui_error "SonarQube is unavailable at ${host}. Run: custodes sonar start"
        return 2
    }

    case "$mode" in
        native) run_sonar_native "$project_key" "$host" "$token" "$wait" "$timeout" ;;
        docker) run_sonar_docker "$project_key" "$host" "$token" "$wait" "$timeout" ;;
        *) ui_error "Unknown CUSTODES_SONAR_MODE: $mode"; return 2 ;;
    esac
}

cmd_sonar() {
    local action="${1:-status}"
    case "$action" in
        scan) run_sonar_scan ;;
        start)
            command_exists docker || { ui_error "Docker CLI not found."; return 2; }
            if docker container inspect sonarqube >/dev/null 2>&1; then
                docker start sonarqube >/dev/null || return 2
                ui_info "Waiting for SonarQube API..."
                local attempt
                for ((attempt = 1; attempt <= 30; attempt++)); do
                    if sonar_server_status >/dev/null; then
                        ui_success "SonarQube is UP: http://localhost:9000"
                        return 0
                    fi
                    sleep 2
                done
                ui_error "Container started, but SonarQube did not become ready in 60 seconds."
                return 2
            else
                ui_error "Container 'sonarqube' was not found."
                return 2
            fi
            ;;
        stop)
            docker stop sonarqube >/dev/null && ui_success "SonarQube container stopped."
            ;;
        logs) docker logs --tail 100 sonarqube ;;
        status)
            ui_section "SonarQube"
            ui_key_value "enabled" "$(config_value CUSTODES_SONAR_ENABLED no)"
            ui_key_value "mode" "$(config_value CUSTODES_SONAR_MODE docker)"
            ui_key_value "server" "$(config_value CUSTODES_SONAR_HOST_URL http://localhost:9000)"
            ui_key_value "project" "$(sonar_project_key 2>/dev/null || printf '-')"
            if sonar_server_status >/dev/null; then
                ui_key_value "health" "UP"
            else
                ui_key_value "health" "unavailable"
            fi
            ;;
        *) ui_error "Usage: custodes sonar [status|start|stop|logs|scan]"; return 2 ;;
    esac
}
