# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

### 飞书语音消息

上传音频：file_type=opus（不是mp3），需要 receive_id_type=chat_id + receive_id
发送消息：msg_type=audio，receive_id_type=chat_id，content 包含 file_key 和 duration

**TTS → 飞书语音流程（本地离线方案）：**
1. `edge-tts` 生成 MP3（需网络）
2. `ffmpeg -i input.mp3 -c:a libopus -b:a 128k output.opus`
3. `lark-cli im +messages-send --user-id <id> --audio ./output.opus --as bot`

**Voice 推荐：**
| 语言 | Voice | 说明 |
|------|-------|------|
| 普通话 | zh-CN-XiaoxiaoNeural | 女声，自然清晰 |
| 粤语 | zh-HK-HiuGaaiNeural | 女声，香港口音 |
| 普通话男声 | zh-CN-YunxiNeural | 男声 |

- 发件邮箱: mailme@yeah.net
- 授权码: DBW8MbYrUNuQf2s9
- SMTP: smtp.yeah.net:465
- 收件人: holycow@qq.com
