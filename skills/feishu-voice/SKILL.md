---
name: feishu-voice
description: "Send TTS voice messages to Feishu users. Uses Microsoft Edge TTS + ffmpeg + lark-cli to generate and deliver natural-sounding voice messages in Mandarin or Cantonese. Triggers: 发语音、发 voice、语音消息、voice message、TTS、飞书语音。"
metadata:
  {
    "openclaw":
      {
        "primaryEnv": "FEISHU_USER_ID",
        "requires": { "bins": ["ffmpeg", "lark-cli"] },
      },
  }
---

# feishu-voice

Send TTS voice messages to Feishu users via edge-tts + ffmpeg + lark-cli.

## Prerequisites

- `edge-tts` (pip install edge-tts)
- `ffmpeg` in PATH
- `lark-cli` configured with Feishu bot credentials

## Voices

| Language | Voice | Description |
|----------|-------|-------------|
| Mandarin F | `zh-CN-XiaoxiaoNeural` | Natural female, default |
| Mandarin M | `zh-CN-YunxiNeural` | Natural male |
| Cantonese | `zh-HK-HiuGaaiNeural` | Hong Kong female |

## Usage

```bash
# Quick send (uses defaults: Mandarin female + default user)
python3 skills/feishu-voice/scripts/send_voice.py -t "早晨老细，收到请回复。"

# Mandarin male
python3 skills/feishu-voice/scripts/send_voice.py -t "测试消息" -v zh-CN-YunxiNeural

# Cantonese
python3 skills/feishu-voice/scripts/send_voice.py -t "早晨老细，語音測試。" -v zh-HK-HiuGaaiNeural

# Custom user ID
python3 skills/feishu-voice/scripts/send_voice.py -t "hello" -u ou_xxx

# Save to file instead of sending
python3 skills/feishu-voice/scripts/send_voice.py -t "hello" -o /tmp/voice.opus

# As shell script (less flexible, useful for cron)
bash skills/feishu-voice/scripts/tts_voice.sh "早晨老细" zh-CN-XiaoxiaoNeural ou_xxx
```

## Script Parameters (tts_voice.sh)

| Arg | Default | Description |
|-----|---------|-------------|
| `$1` text | (required) | Text to speak |
| `$2` voice | `zh-CN-XiaoxiaoNeural` | Voice ShortName |
| `$3` user_id | `ou_ce03d55a9a1b32f100e467e910222c5b` | Feishu user open_id |

## Python Script Parameters (send_voice.py)

| Flag | Default | Description |
|------|---------|-------------|
| `-t, --text` | (required) | Text to speak |
| `-v, --voice` | `zh-CN-XiaoxiaoNeural` | Edge TTS voice ShortName |
| `-u, --user-id` | `ou_ce03d55a9a1b32f100e467e910222c5b` | Feishu user open_id |
| `-o, --output` | (send only) | Save to file instead of sending |
| `--no-send` | False | Generate but don't send |