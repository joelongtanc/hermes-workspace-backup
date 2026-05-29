# Daily Backup Summary

## 2026-05-29
- Backup: `backup-2026-05-29.tar.gz` (725KB)
- Status: SUCCESS
- GitHub URL: https://github.com/joelongtanc/hermes-workspace-backup/blob/main/backup-2026-05-29.tar.gz

## Contents
- `.hermes/` - Hermes config (skills symlinks, config.yaml)
- `.agents/` - 32 skills (Lark suite, TTS, etc.)
- `memories/` - MEMORY.md, USER.md
- `.env` - sanitized (API keys masked as BACKUP_KEY)

## Excluded
- Large model files (TTS kokoro model, voice bin)
- Cache directories
- Database files (state.db, response_store.db)
- Slide XML templates
