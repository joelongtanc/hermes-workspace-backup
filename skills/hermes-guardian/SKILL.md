# Hermes Guardian — 运作保障机制

## 概述

自动监控 + 自动修复 `hermes-gateway.service`，无需人工干预。

---

## 工作原理

```
hermes-gateway.service (systemd托管)
         ↓
每日 09:00 & 21:00 定时触发 health_check.sh
         ↓
检测到异常 → 自动执行对应修复
         ↓
结果写入 last_check.json + last_alert.txt（如有告警）
```

---

## 健康检查项目

| 检查项 | 阈值 | 动作 |
|--------|------|------|
| 重启计数器增量（5分钟内） | > 3次 | ⚠️ 告警 |
| Feishu 连接冲突日志 | 存在 | 🔴 自动清理+重启 |
| StartLimitBurst 触发 | 是 | 🔴 禁用服务 |
| 服务非 active（非启动中） | 是 | 🔴 重启服务 |
| 进程不存在但服务说 active | 是 | 🔴 重启服务 |
| openclaw-gateway 离线 | 是 | ⚠️ 告警 |

---

## 自动修复策略

### 情况1：Feishu 连接冲突导致 crash loop
```
1. systemctl stop hermes-gateway.service
2. rm /root/.hermes/gateway.lock + gateway.pid
3. pkill 所有残留 hermes_cli 进程
4. sleep 5（等连接释放）
5. systemctl start hermes-gateway.service
```

### 情况2：StartLimitBurst 触发（systemd 放弃重启）
```
1. systemctl stop hermes-gateway.service
2. systemctl disable hermes-gateway.service
3. rm 锁文件
```

### 情况3：服务僵死/崩溃
```
→ systemctl restart hermes-gateway.service
```

---

## 文件结构

```
/root/.openclaw/workspace/skills/hermes-guardian/
├── SKILL.md              ← 本文档
├── health_check.sh       ← 主脚本（可独立运行）
├── last_check.json       ← 最近检查状态
├── last_alert.txt        ← 最近告警内容（如有）
└── guardian.log          ← 运行日志
```

---

## 定时任务

```
# 每日 09:00 和 21:00
0 9,21 * * * /root/.openclaw/workspace/skills/hermes-guardian/health_check.sh
```

---

## systemd 修复（2026-05-06）

原 `hermes-gateway.service` 存在 crash loop 问题（RestartSec=10 太短，旧进程未退出新进程就起），已修复：

```ini
[Service]
ExecStartPre=/bin/sleep 30   # 启动前等30秒让旧进程完全退出
RestartSec=30                 # 重启间隔从10秒改为30秒
StartLimitIntervalSec=300     # 5分钟窗口
StartLimitBurst=3             # 窗口内最多重启3次，超限则放弃
TimeoutStartSec=60
```

---

## 手动命令

```bash
# 手动运行健康检查
/root/.openclaw/workspace/skills/hermes-guardian/health_check.sh

# 查看最近状态
cat /root/.openclaw/workspace/skills/hermes-guardian/last_check.json

# 查看最近告警
cat /root/.openclaw/workspace/skills/hermes-guardian/last_alert.txt

# 查看日志
tail -20 /root/.openclaw/workspace/skills/hermes-guardian/guardian.log

# 手动重启服务
systemctl restart hermes-gateway.service

# 手动停止并禁用服务
systemctl stop hermes-gateway.service && systemctl disable hermes-gateway.service
```

---

## 两套飞书机器人并行

| 服务 | Feishu App ID | 说明 |
|------|---------------|------|
| openclaw-gateway | `cli_a952f7408138dccc` | 虾2号（我）|
| hermes-gateway | `cli_a9360423ba3cdcee` | Hermes agent |
