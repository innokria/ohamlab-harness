#!/usr/bin/env bash
set -Eeuo pipefail
export OHAMLAB_DEBUG="${OHAMLAB_DEBUG:-0}"
export OHAMLAB_REFRESH_AUDIO="${OHAMLAB_REFRESH_AUDIO:-0}"
START_SECONDS=$SECONDS
log_stage() { echo "[TIMING] +$((SECONDS - START_SECONDS))s $*"; }
# ============================================================
# OHAMLAB HARNESS CONFIGURATION
# ============================================================
export OHAMLAB_HARNESS_HOME="${OHAMLAB_HARNESS_HOME:-/app/ohamlab-harness}"
export DSH_HOME=/data/dsh
export OHAMLAB_PERSISTENT_DSH_HOME=/data/dsh
export DSH_HOST="${DSH_HOST:-127.0.0.1}"
export DSH_PORT="${DSH_PORT:-3080}"
export PORT="${PORT:-7860}"
export OHAMLAB_REPO_URL="https://github.com/innokria/ohamlab-harness.git"
export OHAMLAB_HARNESS_TAG=main
export OHAMLAB_INTEGRATION_TAG=main
export DSH_TELEMETRY_DISABLED=1
unset DEEPSEEK_API_KEY
export GRADIO_ANALYTICS_ENABLED=False
export HARNS_BRAND_NAME="OhamLab"
# VoiceStudio Python service
export OHAMLAB_AUDIO_REPO="${OHAMLAB_AUDIO_REPO:-https://github.com/innokria/ohamlab-voicestudio.git}"
export OHAMLAB_AUDIO_HOME="${OHAMLAB_AUDIO_HOME:-/app/ohamlab-voicestudio}"
export OHAMLAB_AUDIO_VENV="${OHAMLAB_AUDIO_VENV:-/app/ohamlab-voice-venv}"
export OHAMLAB_AUDIO_HOST="${OHAMLAB_AUDIO_HOST:-127.0.0.1}"
export OHAMLAB_AUDIO_PORT="${OHAMLAB_AUDIO_PORT:-8765}"
export OHAMLAB_AUDIO_MODEL="${OHAMLAB_AUDIO_MODEL:-rahul7star/tts-nano-o-hi}"
AUDIO_PID=""
BACKUP_PID=""
HARNESS_PID=""
# ============================================================
# DISABLE DSH SESSION TELEMETRY
# ============================================================
export DSH_TELEMETRY_MODE="DISABLED"
export DSH_TELEMETRY_OTLP_URL=""
export OTEL_SDK_DISABLED="true"
echo "[OHAMLAB] Session telemetry disabled."
# ============================================================
# SESSION PERSISTENCE CONFIGURATION
# ============================================================
SESSION_DIR="${DSH_HOME}/sessions"
LOCAL_SESSION_DIR="${OHAMLAB_LOCAL_SESSION_DIR:-/tmp/ohamlab-dsh-sessions}"
BACKUP_DIR="${OHAMLAB_PERSISTENT_DSH_HOME}/session-backup"
BACKUP_FILE="${BACKUP_DIR}/sessions.tar.gz"
BACKUP_INTERVAL=3600
echo "=========================================================="
echo "[OHAMLAB] Starting OhamLab Harness"
echo "=========================================================="
# ============================================================
# PREPARE DIRECTORIES
# ============================================================
mkdir -p \
    "${DSH_HOME}/plugins" \
    "${DSH_HOME}/skills" \
    "${DSH_HOME}/profiles" \
    "${BACKUP_DIR}" \
    "${DSH_HOME}/cache" \
    "${DSH_HOME}/logs" \
    "${LOCAL_SESSION_DIR}"
# ============================================================
# USE PERSISTENT PROFILE DIRECTLY
# ============================================================
echo "[OHAMLAB] DSH_HOME: ${DSH_HOME}"
echo "[OHAMLAB] Standard CLI profile: ${DSH_HOME}/profiles/web"
if [ -f "${DSH_HOME}/web/profile/package.json" ]; then
    echo '[OHAMLAB] NOTE: /data/dsh/web/profile exists; CLI uses profiles/web.'
fi
# Active sessions must remain on a local POSIX filesystem.
if [ -L "${SESSION_DIR}" ]; then
    if [ "$(readlink -f "${SESSION_DIR}")" != "$(readlink -f "${LOCAL_SESSION_DIR}")" ]; then
        echo "[OHAMLAB] ERROR: Existing sessions symlink points elsewhere."
        exit 1
    fi
elif [ -e "${SESSION_DIR}" ]; then
    echo "[OHAMLAB] ERROR: ${SESSION_DIR} is an existing directory on HF storage."
    echo '[OHAMLAB] Existing data was NOT changed.'
    exit 1
else
    ln -s "${LOCAL_SESSION_DIR}" "${SESSION_DIR}"
fi
printf test > "${LOCAL_SESSION_DIR}/.hardlink-test.tmp"
ln "${LOCAL_SESSION_DIR}/.hardlink-test.tmp" "${LOCAL_SESSION_DIR}/.hardlink-test"
rm -f "${LOCAL_SESSION_DIR}/.hardlink-test.tmp" "${LOCAL_SESSION_DIR}/.hardlink-test"
echo '[OHAMLAB] PASS: local session hard-link test'
# ============================================================
# VERIFY DEPENDENCIES
# ============================================================
echo "[OHAMLAB] Checking dependencies..."
if command -v python3 >/dev/null 2>&1; then
    python3 --version
elif command -v python >/dev/null 2>&1; then
    python --version
else
    echo '[OHAMLAB] ERROR: Python is required by this deployment.'
    exit 1
fi
if command -v ohamlab-harness >/dev/null 2>&1; then
    ohamlab-harness --version || echo '[OHAMLAB] WARNING: harness version check failed'
else
    echo '[OHAMLAB] ERROR: ohamlab-harness command not found.'
    exit 1
fi
command -v tar >/dev/null || {
    echo "[OHAMLAB] ERROR: tar is not installed."
    exit 1
}
# ============================================================
# SESSION BACKUP
# ============================================================
backup_sessions() {
    local TEMP_BACKUP="/tmp/ohamlab-session-backup.$$.tar.gz"
    echo "[OHAMLAB] Creating session backup..."
    if tar -czf "${TEMP_BACKUP}" \
        -C "$(dirname "${LOCAL_SESSION_DIR}")" \
        "$(basename "${LOCAL_SESSION_DIR}")"; then
        mv -f "${TEMP_BACKUP}" "${BACKUP_FILE}"
        echo "[OHAMLAB] Session backup successful."
        echo "[OHAMLAB] Backup: ${BACKUP_FILE}"
    else
        rm -f "${TEMP_BACKUP}"
        echo "[OHAMLAB] ERROR: Session backup failed."
        return 1
    fi
}
# ============================================================
# RESTORE SESSIONS
# ============================================================
restore_sessions() {
    if [ ! -f "${BACKUP_FILE}" ]; then
        echo "[OHAMLAB] No previous session backup found."
        return 0
    fi
    if [ -z "$(find "${LOCAL_SESSION_DIR}" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        echo "[OHAMLAB] Restoring previous sessions..."
        if tar -tzf "${BACKUP_FILE}" >/dev/null 2>&1; then
            tar -xzf "${BACKUP_FILE}" \
                -C "${LOCAL_SESSION_DIR}" \
                --strip-components=1
            echo "[OHAMLAB] Session restoration successful."
        else
            echo "[OHAMLAB] ERROR: Invalid session backup."
            return 1
        fi
    else
        echo "[OHAMLAB] Existing local sessions detected."
        echo "[OHAMLAB] Skipping restoration."
    fi
}
# ============================================================
# HOURLY BACKUP WORKER
# ============================================================
hourly_backup() {
    echo "[OHAMLAB] Hourly session backup enabled."
    while true; do
        sleep "${BACKUP_INTERVAL}"
        backup_sessions || true
    done
}
# ============================================================
# VERIFY BUILT APPLICATION (no runtime installation)
# ============================================================
DSH_APP_DIR="${OHAMLAB_HARNESS_HOME}/app"
export DSH_APP_DIR
 test -f "${DSH_APP_DIR}/package.json"
restore_sessions
# Reject legacy profiles instead of silently loading old plugins.
for profile in "${DSH_HOME}/profiles/web" "${DSH_HOME}/web/profile"; do
    if [ -f "${profile}/package.json" ] && grep -Eq '@deepseek-ai/|@ohamlab/harness-(brand|voice)' "${profile}/package.json"; then
        echo "[OHAMLAB] Legacy profile detected: ${profile}. Back it up and move it aside before restarting."
        exit 1
    fi
done
# ============================================================
# DETECT PYTHON
# ============================================================
echo "[OHAMLAB] Detecting Python..."
if [ -n "${OHAM_PYTHON:-}" ]; then
    if ! command -v "${OHAM_PYTHON}" >/dev/null 2>&1; then
        echo "[OHAMLAB] ERROR: Configured Python not found: ${OHAM_PYTHON}"
        exit 1
    fi
elif command -v python3 >/dev/null 2>&1; then
    OHAM_PYTHON="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
    OHAM_PYTHON="$(command -v python)"
else
    echo "[OHAMLAB] ERROR: Python not installed."
    exit 1
fi
export OHAM_PYTHON
echo "[OHAMLAB] PASS: Python found at ${OHAM_PYTHON}"
"${OHAM_PYTHON}" --version




# ============================================================
# VOICE UI PLUGIN
# ============================================================
# harness-voice is installed directly from vendor/ohamlab/plugins.
# Its committed client.js/index.js and Cordis patch are used as-is.
# Do not run a build step or expect lib/client.js.

# ============================================================
# INSTALL AND START VOICESTUDIO
# ============================================================
install_ohamlab_audio() {
    local repo="${OHAMLAB_AUDIO_HOME}"
    local venv="${OHAMLAB_AUDIO_VENV}"
    local cli="${venv}/bin/ohamlab-voice"
    local log="${DSH_HOME}/logs/voicestudio.log"
    echo
    echo "=========================================================="
    echo "[OHAMLAB AUDIO] Installing OhamLab VoiceStudio"
    echo "=========================================================="
    command -v git >/dev/null 2>&1 || {
        echo '[OHAMLAB AUDIO] WARNING: git unavailable; skipping VoiceStudio'
        return 1
    }
    if [ "$OHAMLAB_REFRESH_AUDIO" = 0 ] && [ -x "$cli" ] && [ -f "${repo}/pyproject.toml" ] && [ -f "${venv}/.ohamlab-audio-ready" ]; then
        echo "[OHAMLAB AUDIO] Existing installation verified."
    else
    if [ -d "${repo}/.git" ]; then
        echo "[OHAMLAB AUDIO] Updating ${repo} from main"
        git -C "${repo}" fetch --depth 1 origin main || {
            echo '[OHAMLAB AUDIO] WARNING: git fetch failed'
            return 1
        }
        git -C "${repo}" checkout -f main >/dev/null 2>&1 || true
        git -C "${repo}" reset --hard origin/main || {
            echo '[OHAMLAB AUDIO] WARNING: git reset failed'
            return 1
        }
    else
        rm -rf "${repo}"
        git clone --depth 1 --branch main \
            "${OHAMLAB_AUDIO_REPO}" "${repo}" || {
            echo '[OHAMLAB AUDIO] WARNING: clone failed'
            return 1
        }
    fi
    [ -f "${repo}/pyproject.toml" ] || {
        echo '[OHAMLAB AUDIO] WARNING: pyproject.toml missing'
        return 1
    }
    if [ ! -x "${venv}/bin/python" ]; then
        "${OHAM_PYTHON}" -m venv "${venv}" || {
            echo '[OHAMLAB AUDIO] WARNING: could not create audio virtualenv'
            return 1
        }
    fi
    "${venv}/bin/python" -m pip install --upgrade pip || {
        echo '[OHAMLAB AUDIO] WARNING: pip upgrade failed'
    }
    "${venv}/bin/python" -m pip install -e "${repo}[tts,asr,studio]" || {
        echo '[OHAMLAB AUDIO] WARNING: VoiceStudio dependencies failed'
        return 1
    }
    touch "${venv}/.ohamlab-audio-ready"
    fi
    [ -x "${cli}" ] || {
        echo '[OHAMLAB AUDIO] WARNING: ohamlab-voice CLI missing'
        return 1
    }
    if [ -n "${AUDIO_PID}" ] && kill -0 "${AUDIO_PID}" 2>/dev/null; then
        echo "[OHAMLAB AUDIO] VoiceStudio already running."
        return 0
    fi
    export GRADIO_SERVER_NAME="${OHAMLAB_AUDIO_HOST}"
    export GRADIO_SERVER_PORT="${OHAMLAB_AUDIO_PORT}"
    export GRADIO_ANALYTICS_ENABLED="False"
    echo "[OHAMLAB AUDIO] Starting studio on ${OHAMLAB_AUDIO_HOST}:${OHAMLAB_AUDIO_PORT}"
    echo "[OHAMLAB AUDIO] Log: ${log}"
    "${cli}" studio \
        --model "${OHAMLAB_AUDIO_MODEL}" \
        --device cpu \
        >"${log}" 2>&1 &
    AUDIO_PID=$!
    trap 'kill -TERM "$AUDIO_PID" 2>/dev/null || true; wait "$AUDIO_PID" 2>/dev/null || true; exit 0' TERM INT
    sleep 5
    if kill -0 "${AUDIO_PID}" 2>/dev/null; then
        echo "[OHAMLAB AUDIO] VoiceStudio process started (PID ${AUDIO_PID})"
        wait "$AUDIO_PID"
    else
        echo '[OHAMLAB AUDIO] WARNING: VoiceStudio exited; check its log'
        AUDIO_PID=""
        return 1
    fi
}
# ============================================================
# VERIFY SEARCH AND AGENT LAB
# ============================================================
echo
echo "[OHAMLAB] Verifying local Search and Agent Lab..."
"${OHAM_PYTHON}" -m pip show ohamlab-agent >/dev/null 2>&1 || {
    echo "[OHAMLAB] ERROR: ohamlab-agent not installed!"
    exit 1
}
"${OHAM_PYTHON}" -m pip show ohamlab-agent-lab >/dev/null 2>&1 || {
    echo "[OHAMLAB] ERROR: ohamlab-agent-lab not installed!"
    exit 1
}
echo "[OHAMLAB] PASS: Search package installed"
echo "[OHAMLAB] PASS: Agent Lab package installed"
# ============================================================
# INSPECT AGENT LAB
# ============================================================
echo
echo "[OHAMLAB] Inspecting Agent Lab installation..."
"${OHAM_PYTHON}" - <<'PY'
from importlib.metadata import distribution
dist = distribution("ohamlab-agent-lab")
print("[OHAMLAB] Agent Lab version:", dist.version)
top_level = dist.read_text("top_level.txt")
print("[OHAMLAB] Python modules:")
print(top_level or "No top_level.txt available")
print("[OHAMLAB] Registered executable entry points:")
for entry in dist.entry_points:
    if entry.group == "console_scripts":
        print(f"  {entry.name} = {entry.value}")
print("[OHAMLAB] Agent Lab package inspection complete.")
PY
# ============================================================
# VERIFY PYTHON DEPENDENCIES
# ============================================================
echo
echo "[OHAMLAB] Checking Python dependencies..."
"${OHAM_PYTHON}" -m pip check
echo "[OHAMLAB] PASS: Python dependencies verified"
# ============================================================
# VERIFY OHAMLAB CLI
# ============================================================
if command -v ohamlab >/dev/null 2>&1; then
    echo "[OHAMLAB] PASS: OhamLab CLI available"
    command -v ohamlab
else
    echo "[OHAMLAB] WARNING: OhamLab CLI unavailable"
fi
# ============================================================
# CONFIGURE DSH PROVIDERS
# ============================================================
echo
echo "=========================================================="
echo "[OHAMLAB] Configuring DSH providers"
echo "=========================================================="
SETTINGS_FILE="${DSH_HOME}/settings.yaml"
cat > "${SETTINGS_FILE}" <<'EOF'
# ============================================================
# OhamLab Harness - LLM Provider Pool
# ============================================================
llm-pi-ai:
  providers:
    HF:
      displayName: HUGGUN
      api: openai-completions
      baseURL: https://rahul7star-Qwen3-9B.hf.space/v1
      apiKeyEnv: HF_TOKEN
      timeoutMs: 120000
      models:
        - id: Qwen3-9B
    HFQWEN:
      displayName: HUGGUN-Xing
      api: openai-completions
      baseURL: https://rahul7star-xing4-0-29b-a4b.hf.space/v1
      apiKeyEnv: HF_TOKEN
      timeoutMs: 120000
      models:
        - id: Xing
    HFQWENX:
      displayName: HUGGUN-XingXX
      api: openai-completions
      baseURL: https://rahul7star-xing4-0-29b-a4b.hf.space/v1/chat/completions
      apiKeyEnv: HF_TOKEN
      timeoutMs: 120000
      models:
        - id: Xing
    kilo:
      displayName: Kilo Free
      api: openai-completions
      baseURL: https://api.kilo.ai/api/gateway
      apiKeyEnv: DASHSCOPE_API_KEY
      timeoutMs: 120000
      models:
        - id: nvidia/nemotron-3-ultra-550b-a55b:free
        - id: stepfun/step-3.7-flash:free
        - id: nvidia/nemotron-3-super-120b-a12b:free
        - id: nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free
        - id: poolside/laguna-s-2.1:free
        - id: poolside/laguna-xs-2.1:free
        - id: cohere/north-mini-code:free

        - id: tencent/hy3:free
        - id: nvidia/nemotron-3.5-lightning:free
        - id: liquid/lfm-2.5-2.6b:free
    ovh:
      displayName: ALIBABA NEW
      api: openai-completions
      baseURL: https://dashscope-intl.aliyuncs.com/compatible-mode/v1
      apiKeyEnv: DASHSCOPE_API_KEY
      timeoutMs: 120000
      models:
        - id: kimi-k3
        - id: qwen3-coder-flash
        - id: qwen3.5-27b
        - id: qwen3-235b-a22b-thinking-2507
        - id: qwen-plus-2025-07-28
        - id: qwen3.6-plus
        - id: glm-5.2
        - id: glm-5.3

        - id: qwen3.6-flash
        - id: qwen3-vl-plus-2025-09-23
        - id: Mistral-7B-Instruct-v0.3
    nvidia:
      displayName: NVIDIA NIM
      api: openai-completions
      baseURL: https://integrate.api.nvidia.com/v1
      apiKeyEnv: NVIDIA_API_KEY
      timeoutMs: 120000
      models:
        - id: nvidia/nemotron-3.5-lightning-30b-a3b
        - id: nvidia/nemotron-3.5-super-vl-120b-a12b
        - id: z-ai/glm-5.3
        - id: moonshotai/kimi-k3
        - id: openai/gpt-oss-safeguard-20b
        - id: meta/muse-glimmer-30b
        - id: nvidia/nemotron-3-ultra-550b-a55b
        - id: nvidia/nemotron-3-nano-omni-30b-a3b-reasoning
        - id: nvidia/nemotron-3-super-120b-a12b
        - id: qwen/qwen3.8-27b
    dashscope_extra:
      displayName: Alibaba Extra Models
      api: openai-completions
      baseURL: https://dashscope-intl.aliyuncs.com/compatible-mode/v1
      apiKeyEnv: DASHSCOPE_API_KEY
      timeoutMs: 120000
      models:
        - id: qwen3-vl-32b-thinking

        - id: qwen3.8-max
        - id: qwen3-max
        - id: glm-5.1
        - id: qwen3.7-plus
    openrouter:
      displayName: OpenRouter - Dynamic Free
      api: openai-completions
      baseURL: https://openrouter.ai/api/v1
      apiKeyEnv: OPENROUTER_API_KEY
      timeoutMs: 120000
      models:

        - id: nvidia/nemotron-3-ultra-550b-a55b:free
        - id: qwen/qwen3-coder:free
    huggingface:
      displayName: Hugging Face Router
      api: openai-completions
      baseURL: https://router.huggingface.co/v1
      apiKeyEnv: HF_TOKEN
      timeoutMs: 120000
      models:
        - id: openai/gpt-oss-120b
        - id: openai/gpt-oss-20b
    dashscope_qwen_flash_next:
      displayName: Qwen 3.8 Flash Next
      api: openai-completions
      baseURL: https://dashscope-intl.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1
      apiKeyEnv: DASHSCOPE_API_KEY
      timeoutMs: 120000
      models:
        - id: Qwen/Qwen3.8-Flash-Next
    qwen:
      displayName: Qwen 3.8 Flash Next
      api: openai-completions
      baseURL: https://pnywsahxhac1qjbo.us-east-2.aws.endpoints.huggingface.cloud/v1
      apiKeyEnv: HF_TOKEN
      timeoutMs: 120000
      models:
        - id: Qwen/Qwen3.8-Flash-Next
    llama:
      displayName: LFM2.5 Local
      api: openai-completions
      baseURL: http://127.0.0.1:8000/v1
      apiKeyEnv: LLAMA_API_KEY
      timeoutMs: 120000
      models:
        - id: LFM2.5
agent-default-model:
  provider: HF
  model: Qwen3-9B
EOF
chmod 600 "${SETTINGS_FILE}"
echo "[DSH] Settings file: ${SETTINGS_FILE}"
echo "[DSH] Provider pool configured"
echo "[DSH] Default model: HF / Qwen3-9B"
# ============================================================
# VERIFY NGINX
# ============================================================
echo "[OHAMLAB] Checking Nginx..."
nginx -t
# ============================================================
# START HOURLY BACKUP WORKER
# ============================================================
hourly_backup &
BACKUP_PID=$!
# ============================================================
# GRACEFUL SHUTDOWN
# ============================================================
shutdown() {
    echo "[OHAMLAB] Shutdown requested."
    trap - TERM INT
    if [ -n "${BACKUP_PID}" ]; then
        kill "${BACKUP_PID}" 2>/dev/null || true
        wait "${BACKUP_PID}" 2>/dev/null || true
    fi
    if [ -n "${AUDIO_PID}" ]; then
        kill -TERM "${AUDIO_PID}" 2>/dev/null || true
        wait "${AUDIO_PID}" 2>/dev/null || true
    fi
    if [ -n "${HARNESS_PID}" ]; then
        kill -TERM "${HARNESS_PID}" 2>/dev/null || true
        wait "${HARNESS_PID}" 2>/dev/null || true
    fi
    nginx -s quit 2>/dev/null || true
    backup_sessions || {
        echo "[OHAMLAB] WARNING: Final backup failed."
    }
    echo "[OHAMLAB] Shutdown complete."
    exit "${1:-0}"
}
trap shutdown TERM INT
# ============================================================
# RUNTIME DIAGNOSTICS
# ============================================================
echo "[OHAMLAB DEBUG] DSH_HOME=${DSH_HOME}"
for profile in "${DSH_HOME}/profiles/web" "${DSH_HOME}/web/profile"; do
    if [ -d "${profile}" ]; then
        echo "[OHAMLAB DEBUG] Found profile: ${profile}"
        ls -la "${profile}"
    fi
done
echo "[OHAMLAB DEBUG] Registered plugins:"
( cd "${DSH_APP_DIR}"; timeout 30s pnpm dsh plugin --profile web list ) || true
ls -ld "${DSH_HOME}/sessions" "${SETTINGS_FILE}" || true
# ============================================================
# LAUNCH OHAMLAB HARNESS
# ============================================================
echo "=========================================================="
echo "[OHAMLAB] Launching OhamLab Harness..."
echo "=========================================================="
log_stage "Launching Harness"
# Use the full public Hugging Face hostname for browser trust.
TRUSTED_HOST="${DSH_TRUSTED_HOST:-${SPACE_HOST:-rahul7star-harnesss.hf.space}}"
if [[ "${TRUSTED_HOST}" != *.* ]]; then
    TRUSTED_HOST="${TRUSTED_HOST}.hf.space"
fi
export DSH_TRUSTED_HOST="${TRUSTED_HOST}"
echo "[OHAMLAB] Trusted host: ${DSH_TRUSTED_HOST}"
(
    cd "${DSH_APP_DIR}"
    exec pnpm dsh web \
        --host "${DSH_HOST}" \
        --port "${DSH_PORT}" \
        --no-open \
        --trusted-host "${DSH_TRUSTED_HOST}"
) &
HARNESS_PID=$!

echo "[OHAMLAB] Waiting for Harness backend..."
HARNESS_READY=0
for attempt in $(seq 1 90); do
    if ! kill -0 "${HARNESS_PID}" 2>/dev/null; then
        echo "[OHAMLAB] ERROR: Harness exited during startup"
        break
    fi
    if curl -fsS --max-time 2 "http://${DSH_HOST}:${DSH_PORT}/" >/dev/null 2>&1; then
        HARNESS_READY=1
        break
    fi
    sleep 1
done
if [ "${HARNESS_READY}" != 1 ]; then
    echo "[OHAMLAB] ERROR: Harness backend failed readiness check"
    shutdown 1
fi
echo "[OHAMLAB] Harness HTTP backend is ready"
echo "[OHAMLAB] Starting Nginx..."
nginx
# Run optional audio setup separately; exec the service in the worker so
# the parent can terminate it using the tracked PID.
if [ "${OHAMLAB_ENABLE_AUDIO:-0}" = 1 ]; then
    ( install_ohamlab_audio ) &
    AUDIO_PID=$!
fi
set +e
wait "${HARNESS_PID}"
HARNESS_STATUS=$?
set -e
# ============================================================
# CLEANUP AFTER HARNESS EXIT
# ============================================================
echo "[OHAMLAB] Harness stopped."
nginx -s quit 2>/dev/null || true
if [ -n "${AUDIO_PID}" ]; then
    kill -TERM "${AUDIO_PID}" 2>/dev/null || true
    wait "${AUDIO_PID}" 2>/dev/null || true
fi
kill "${BACKUP_PID}" 2>/dev/null || true
wait "${BACKUP_PID}" 2>/dev/null || true
backup_sessions || true
echo "[OHAMLAB] Harness exit status: ${HARNESS_STATUS}"
exit "${HARNESS_STATUS}"
