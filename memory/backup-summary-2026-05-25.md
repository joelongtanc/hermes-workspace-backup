=== Hermes Agent Backup Summary ===
Date: 2026-05-25
Status: SUCCESS

Files Backed Up:
- /opt/data/.hermes/ (config, skills symlinks, .env with redacted API keys)
- /opt/data/.agents/ (28 skill directories)

Skills Included:
- lark-* (approval, attendance, base, calendar, contact, doc, drive, event, im, mail, markdown, minutes, okr, openapi-explorer, shared, sheets, skill-maker, slides, task, vc, vc-agent, whiteboard, wiki, workflow-meeting-summary, workflow-standup-report)
- tts, speech-to-text, video-translation, wps
- characteristic-voice, chat-with-anyone, daily-news-caster, sound-fx, template-skill

Backup Archive:
- Local: /opt/data/home/backup-2026-05-25.tar.gz (4.2 MB)
- GitHub: joelongtanc/hermes-workspace-backup/backup-2026-05-25.tar.gz

Notes:
- API keys redacted (FEISHU_APP_SECRET = BACKUP_KEY)
- Excluded: cache, node_modules, __pycache__
