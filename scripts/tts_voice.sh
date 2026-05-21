#!/bin/bash
# tts_voice.sh - Send TTS voice message to Feishu user
# Usage: ./tts_voice.sh "text" [voice] [user_id]
# Default voice: zh-CN-XiaoxiaoNeural (Mandarin female)
# Default user: ou_ce03d55a9a1b32f100e467e910222c5b (rc)

VOICE="$2"
USER_ID="$3"
OUTPUT_DIR="/root/.openclaw/workspace"
TMP_DIR=$(mktemp -d)

TMP_MP3="$TMP_DIR/temp_tts.mp3"
TMP_OPUS="$TMP_DIR/temp_tts.opus"
LOCAL_OPUS="$OUTPUT_DIR/temp_voice_$$.opus"

# Generate MP3 via edge-tts (requires network)
python3 -c "
import edge_tts, asyncio
async def main():
    communicate = edge_tts.Communicate('$TEXT', '$VOICE')
    await communicate.save('$TMP_MP3')
asyncio.run(main())
" || { echo "edge-tts failed"; rm -rf $TMP_DIR; exit 1; }

# Convert to OPUS
ffmpeg -i "$TMP_MP3" -c:a libopus -b:a 128k "$TMP_OPUS" -y 2>&1 | tail -1

# Copy to workspace (lark-cli needs relative path)
cp "$TMP_OPUS" "$LOCAL_OPUS"

# Send via lark-cli
cd "$OUTPUT_DIR"
lark-cli im +messages-send --user-id "$USER_ID" --audio "./temp_voice_$$.opus" --as bot 2>&1

rm -f "$LOCAL_OPUS"
rm -rf "$TMP_DIR"
echo "Done"