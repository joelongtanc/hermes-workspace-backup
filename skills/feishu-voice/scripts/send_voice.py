#!/usr/bin/env python3
"""
send_voice.py - Send TTS voice messages to Feishu via edge-tts + ffmpeg + lark-cli

Usage:
  python3 send_voice.py -t "text" [-v voice] [-u user_id] [-o output_file] [--no-send]

Voices:
  zh-CN-XiaoxiaoNeural  (Mandarin female, default)
  zh-CN-YunxiNeural     (Mandarin male)
  zh-HK-HiuGaaiNeural   (Cantonese female)
"""

import argparse
import asyncio
import os
import subprocess
import tempfile
import sys

DEFAULT_USER = "ou_ce03d55a9a1b32f100e467e910222c5b"
DEFAULT_VOICE = "zh-CN-XiaoxiaoNeural"
WORKSPACE = "/root/.openclaw/workspace"


def parse_args():
    p = argparse.ArgumentParser(description="Send TTS voice to Feishu")
    p.add_argument("-t", "--text", required=True, help="Text to speak")
    p.add_argument("-v", "--voice", default=DEFAULT_VOICE, help=f"Edge TTS voice (default: {DEFAULT_VOICE})")
    p.add_argument("-u", "--user-id", dest="user_id", default=DEFAULT_USER, help=f"Feishu open_id (default: {DEFAULT_USER})")
    p.add_argument("-o", "--output", default=None, help="Output file path (default: send to Feishu)")
    p.add_argument("--no-send", action="store_true", help="Generate but don't send")
    return p.parse_args()


async def generate_audio(text: str, voice: str, output_path: str):
    import edge_tts
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(output_path)
    print(f"[edge-tts] Generated: {output_path}", file=sys.stderr)


def convert_to_opus(mp3_path: str, opus_path: str):
    result = subprocess.run(
        ["ffmpeg", "-i", mp3_path, "-c:a", "libopus", "-b:a", "128k", opus_path, "-y"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg failed: {result.stderr[-500:]}")
    print(f"[ffmpeg] Converted: {opus_path}", file=sys.stderr)


def send_voice(opus_path: str, user_id: str):
    # lark-cli requires audio file to be within cwd — copy to workspace
    local_opus = os.path.join(WORKSPACE, f"temp_voice_{os.path.basename(opus_path)}")
    subprocess.run(["cp", opus_path, local_opus])
    try:
        result = subprocess.run(
            ["lark-cli", "im", "+messages-send", "--user-id", user_id, "--audio", f"./temp_voice_{os.path.basename(opus_path)}", "--as", "bot"],
            capture_output=True, text=True, cwd=WORKSPACE
        )
        if result.returncode != 0:
            raise RuntimeError(f"lark-cli failed: {result.stdout} {result.stderr}")
        print(f"[lark-cli] Sent: {result.stdout}", file=sys.stderr)
    finally:
        if os.path.exists(local_opus):
            os.remove(local_opus)


def main():
    args = parse_args()

    with tempfile.TemporaryDirectory() as tmpdir:
        mp3_path = os.path.join(tmpdir, "temp_tts.mp3")
        opus_path = os.path.join(tmpdir, "temp_tts.opus")

        # Step 1: Generate MP3
        asyncio.run(generate_audio(args.text, args.voice, mp3_path))

        # Step 2: Convert to OPUS
        convert_to_opus(mp3_path, opus_path)

        # Step 3: Send or save
        if args.no_send or args.output:
            final_path = args.output or os.path.join(WORKSPACE, f"voice_voice_{os.path.basename(opus_path)}")
            subprocess.run(["cp", opus_path, final_path])
            print(f"Saved to: {final_path}")
        else:
            send_voice(opus_path, args.user_id)
            print("Voice message sent successfully.")


if __name__ == "__main__":
    main()