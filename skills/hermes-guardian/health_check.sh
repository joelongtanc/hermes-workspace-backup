#!/bin/bash
# hermes-guardian: cron 托管的健康检查 + 重启脚本
# 每3分钟由 cron 触发，检查 hermes-gateway 是否存活，不在则拉起
set -uo pipefail

SKILL_DIR="/root/.openclaw/workspace/skills/hermes-guardian"
STATE_FILE="$SKILL_DIR/last_check.json"
LOG_FILE="$SKILL_DIR/guardian.log"
HERMES_LOG="/root/.hermes/logs/gateway.log"
SERVICE_NAME="hermes-gateway.service"

JOURNAL_SINCE_MINUTES=5
MAX_RESTARTS_IN_INTERVAL=5

log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" >> "$LOG_FILE"; }

# ── 收集状态 ─────────────────────────────────────────────────────────────────
HERMES_PID=$(ps aux | grep -E "hermes_cli.*gateway.*run" | grep -v grep | awk '{print $2}' | head -1 || echo "")
HERMES_RUNNING=$([ -n "$HERMES_PID" ] && echo "yes" || echo "no")

OPENCLAW_PID=$(ps aux | grep "openclaw-gateway" | grep -v grep | awk '{print $2}' | head -1 || echo "")
OPENCLAW_RUNNING=$([ -n "$OPENCLAW_PID" ] && echo "yes" || echo "no")

FEISHU_LAST_CONNECT=$(grep -i "connected" "$HERMES_LOG" 2>/dev/null | tail -1 | grep -o '\[.*\]' | tr -d '[]' | sed 's/,.*//' || echo "none")

# Safer: capture exit code explicitly
_count=$(grep -c "Another local Hermes gateway is already using this Feishu app_id" "$HERMES_LOG" 2>/dev/null)
[ $? -ne 0 ] || [ -z "$_count" ] && _count=0
HAS_CONFLICT=$_count

_jcount=$(sudo journalctl -u "$SERVICE_NAME" --since "${JOURNAL_SINCE_MINUTES} minutes ago" --no-pager 2>/dev/null | grep -c "Started hermes-gateway.service")
[ $? -ne 0 ] || [ -z "$_jcount" ] && _jcount=0
STARTS_SINCE=$_jcount

PREV_STATUS=$(grep -o '"status": "[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: "//;s/"//' || echo "UNKNOWN")

# ── 判断 ──
status="OK"; severity="OK"; message=""; action="none"

if [ "$HERMES_RUNNING" = "no" ]; then
    status="DOWN"; severity="CRITICAL"
    message="hermes-gateway 进程不存在，需要启动"
    action="start_service"
elif [ "$HAS_CONFLICT" -gt 0 ]; then
    status="WARNING"; severity="WARNING"
    message="检测到 Feishu 连接冲突历史日志"
    action="observe"
elif [ "$STARTS_SINCE" -gt "$MAX_RESTARTS_IN_INTERVAL" ]; then
    status="WARNING"; severity="WARNING"
    message="${JOURNAL_SINCE_MINUTES}分钟内重启 ${STARTS_SINCE} 次（可能存在 crash loop）"
    action="observe"
elif [ "$OPENCLAW_RUNNING" = "no" ]; then
    status="WARNING"; severity="WARNING"
    message="openclaw-gateway 离线（备用系统）"
    action="observe"
else
    message="正常 | PID ${HERMES_PID} | Feishu=${FEISHU_LAST_CONNECT}"
fi

# ── 执行动作 ──
if [ "$action" = "start_service" ]; then
    log "[CRITICAL] hermes-gateway 进程消失，执行启动"
    /bin/systemctl start "$SERVICE_NAME"
fi

# ── 写状态文件 ──
mkdir -p "$SKILL_DIR"
cat > "$STATE_FILE" <<EOF
{
  "timestamp": "$(date '+%Y-%m-%dT%H:%M:%S%z')",
  "previous_status": "${PREV_STATUS}",
  "hermes_running": "${HERMES_RUNNING}",
  "hermes_pid": "${HERMES_PID:-none}",
  "openclaw_running": "${OPENCLAW_RUNNING}",
  "openclaw_pid": "${OPENCLAW_PID:-none}",
  "feishu_last_connect": "${FEISHU_LAST_CONNECT}",
  "has_feishu_conflict": ${HAS_CONFLICT},
  "restarts_last_${JOURNAL_SINCE_MINUTES}min": ${STARTS_SINCE},
  "status": "${status}",
  "severity": "${severity}",
  "message": "${message}"
}
EOF

# ── 异常告警 ──
if [ "${severity}" != "OK" ]; then
    ALERT_MSG="[Hermes Guardian $(date '+%H:%M:%S')]
【${severity}】hermes-gateway
${message}
进程: ${HERMES_RUNNING}（PID ${HERMES_PID:-N/A}）
openclaw: ${OPENCLAW_RUNNING}（PID ${OPENCLAW_PID:-N/A}）"
    echo "$ALERT_MSG"
    echo "$ALERT_MSG" > "$SKILL_DIR/last_alert.txt"
else
    rm -f "$SKILL_DIR/last_alert.txt"
fi

log "[${severity}] hermes=${HERMES_RUNNING}(${HERMES_PID:-none}) openclaw=${OPENCLAW_RUNNING} action=${action}"
echo "$(date '+%H:%M:%S') — ${status} — ${message}"