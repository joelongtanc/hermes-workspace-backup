#!/bin/bash
# B站视频字幕智能获取脚本 v2.2-mod
# 适配：OpenClaw Linux 服务器（绕过 412 限制）
# 功能：CC字幕 → AI字幕 → Whisper转录（三级降级）

VIDEO_URL="$1"
OUTPUT_DIR="${2:-/tmp}"
WHISPER_VENV="${3:-/root/.hermes/hermes-agent/.venv}"

if [ -z "$VIDEO_URL" ]; then
    echo "用法: $0 <B站视频链接> [输出目录] [Whisper虚拟环境路径]"
    exit 1
fi

YT_DLP="${WHISPER_VENV}/bin/yt-dlp"
WHISPER="${WHISPER_VENV}/bin/whisper"

echo "🔍 正在获取视频信息..."

# ===== 解析 BVID =====
get_bvid() {
    local url="$1"
    # 优先用 API 解析短链
    REAL_URL=$(curl -sI "$url" 2>/dev/null | grep -i "^location:" | sed 's/.*video\///' | cut -d'?' -f1)
    if [ -z "$REAL_URL" ]; then
        # 直接从URL提取
        echo "$url" | grep -oP 'BV[a-zA-Z0-9]+' | head -1
    else
        echo "$REAL_URL" | grep -oP 'BV[a-zA-Z0-9]+' | head -1
    fi
}

BVID=$(get_bvid "$VIDEO_URL")
if [ -z "$BVID" ]; then
    echo "❌ 无法解析 BVID，请检查链接是否正确"
    exit 1
fi

echo "   BVID: $BVID"

# ===== 用 playurl API 获取视频信息（绕过 412）=====
# 先获取 cid
CID_API=$(curl -s "https://api.bilibili.com/x/web-interface/view?bvid=$BVID" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" 2>/dev/null)

CID=$(echo "$CID_API" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('cid',''))" 2>/dev/null)
TITLE=$(echo "$CID_API" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('title',''))" 2>/dev/null)
AUTHOR=$(echo "$CID_API" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('owner',{}).get('name',''))" 2>/dev/null)
DURATION=$(echo "$CID_API" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}).get('duration',0); print(f'{d//60}分{d%60}秒')" 2>/dev/null)
UPLOAD_DATE=$(echo "$CID_API" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('pubdate',''))" 2>/dev/null)

if [ -z "$TITLE" ]; then
    echo "❌ 无法获取视频信息，B站可能限制了中国大陆以外 IP"
    exit 1
fi

if [ -n "$UPLOAD_DATE" ] && [ "$UPLOAD_DATE" != "None" ]; then
    UPLOAD_DATE_FORMATTED=$(date -d "@$UPLOAD_DATE" '+%Y-%m-%d' 2>/dev/null || echo "$UPLOAD_DATE")
else
    UPLOAD_DATE_FORMATTED="未知"
fi

echo "📹 视频: $TITLE"
echo "👤 作者: $AUTHOR"
echo "⏱️  时长: $DURATION"

# ===== 用 playurl API 获取下载链接 =====
echo ""
echo "🔍 正在获取下载链接..."

PLAYURL_API=$(curl -s "https://api.bilibili.com/x/player/playurl?bvid=$BVID&cid=$CID&qn=80&fnval=0&fnver=0&fourk=0" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    -H "Referer: https://www.bilibili.com" 2>/dev/null)

VIDEO_URL_DIRECT=$(echo "$PLAYURL_API" | python3 -c "
import sys,json,urllib.parse
d=json.load(sys.stdin)
if d.get('code') == 0:
    durls = d.get('data',{}).get('durl',[])
    if durls:
        print(durls[0].get('url',''))
" 2>/dev/null)

if [ -z "$VIDEO_URL_DIRECT" ]; then
    echo "❌ 无法获取下载链接"
    exit 1
fi

# ===== 第1级：尝试下载字幕 =====
echo ""
echo "🔍 正在检查字幕..."
mkdir -p "$OUTPUT_DIR"

# 用 yt-dlp 下载字幕（用 playurl 的 referer）
SUB_CHECK=$("$YT_DLP" --no-warnings --list-subs \
    --add-headers "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    --add-headers "Referer:https://www.bilibili.com" \
    "$VIDEO_URL" 2>&1)

HAS_CC_SUBS=false
if echo "$SUB_CHECK" | grep -qE "^[[:space:]]+(zh|en|ja|ko|es|ar|pt|de|fr)-" && echo "$SUB_CHECK" | grep -qv "ai-"; then
    HAS_CC_SUBS=true
fi

HAS_AI_SUBS=false
AI_LANG=""
for lang in "ai-zh" "zh-CN" "zh" "en" "ja"; do
    if echo "$SUB_CHECK" | grep -q "$lang"; then
        HAS_AI_SUBS=true
        AI_LANG="$lang"
        break
    fi
done

TRANSCRIPT_SOURCE=""
TRANSCRIPT_TEXT=""

# 第1级：CC字幕
if [ "$HAS_CC_SUBS" = true ]; then
    echo "✅ 发现CC字幕，下载中..."
    "$YT_DLP" --no-warnings --skip-download \
        --add-headers "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        --add-headers "Referer:https://www.bilibili.com" \
        --write-subs --sub-langs zh-CN,zh-TW,zh-Hans,zh --convert-subs srt \
        -o "${OUTPUT_DIR}/bilibili_sub.%(ext)s" "$VIDEO_URL" 2>&1 | tail -3
    
    SUB_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "bilibili_sub*.srt" -type f 2>/dev/null | head -1)
    if [ -n "$SUB_FILE" ] && [ -s "$SUB_FILE" ]; then
        TRANSCRIPT_SOURCE="B站CC字幕"
        TRANSCRIPT_TEXT=$(sed '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/d' "$SUB_FILE" | sed '/^[0-9]*$/d' | sed '/^$/d')
        echo "✅ CC字幕获取成功"
    else
        HAS_CC_SUBS=false
    fi
fi

# 第2级：AI字幕
if [ -z "$TRANSCRIPT_TEXT" ] && [ "$HAS_AI_SUBS" = true ]; then
    echo "✅ 发现AI字幕（$AI_LANG），下载中..."
    "$YT_DLP" --no-warnings --skip-download \
        --add-headers "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        --add-headers "Referer:https://www.bilibili.com" \
        --write-subs --write-auto-subs --sub-langs "$AI_LANG" --convert-subs srt \
        -o "${OUTPUT_DIR}/bilibili_ai_sub.%(ext)s" "$VIDEO_URL" 2>&1 | tail -3
    
    SUB_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "bilibili_ai_sub*.srt" -type f 2>/dev/null | head -1)
    if [ -n "$SUB_FILE" ] && [ -s "$SUB_FILE" ]; then
        TRANSCRIPT_SOURCE="B站AI字幕 ($AI_LANG)"
        TRANSCRIPT_TEXT=$(sed '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/d' "$SUB_FILE" | sed '/^[0-9]*$/d' | sed '/^$/d')
        echo "✅ AI字幕获取成功"
    else
        HAS_AI_SUBS=false
    fi
fi

# 第3级：Whisper转录
if [ -z "$TRANSCRIPT_TEXT" ]; then
    echo "🎤 未发现可用字幕，使用 Whisper 转录..."
    echo "⏳ 这可能需要几分钟，请耐心等待..."
    
    # 下载音频（用 playurl 直链）
    AUDIO_FILE="${OUTPUT_DIR}/bilibili_audio.mp3"
    curl -L --max-time 300 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        -H "Referer: https://www.bilibili.com" \
        -o "$AUDIO_FILE" \
        "$VIDEO_URL_DIRECT" 2>&1 | tail -3
    
    if [ ! -s "$AUDIO_FILE" ]; then
        echo "❌ 音频下载失败，尝试用 yt-dlp..."
        "$YT_DLP" --no-warnings -x --audio-format mp3 \
            --add-headers "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
            --add-headers "Referer:https://www.bilibili.com" \
            -o "${OUTPUT_DIR}/bilibili_audio.%(ext)s" "$VIDEO_URL" 2>&1 | tail -5
        AUDIO_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 \( -name "bilibili_audio*.mp3" -o -name "bilibili_audio*.m4a" \) 2>/dev/null | head -1)
    fi
    
    if [ -z "$AUDIO_FILE" ] || [ ! -s "$AUDIO_FILE" ]; then
        echo "❌ 音频下载失败"
        exit 1
    fi
    
    AUDIO_SIZE=$(du -h "$AUDIO_FILE" | cut -f1)
    echo "   音频已下载: $AUDIO_SIZE"
    
    # Whisper 转录
    "$WHISPER" "$AUDIO_FILE" \
        --model small \
        --language Chinese \
        --output_dir "$OUTPUT_DIR" \
        --output_format txt 2>&1 | tail -5
    
    TXT_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.txt" -type f 2>/dev/null | head -1)
    
    if [ -n "$TXT_FILE" ] && [ -s "$TXT_FILE" ]; then
        echo "✅ Whisper 转录完成"
        TRANSCRIPT_SOURCE="Whisper small 模型"
        TRANSCRIPT_TEXT=$(cat "$TXT_FILE")
        rm -f "$TXT_FILE"
    else
        echo "❌ 转录失败"
        exit 1
    fi
fi

# 清理音频
rm -f "$AUDIO_FILE" "${OUTPUT_DIR}/bilibili_sub"*.srt "${OUTPUT_DIR}/bilibili_ai_sub"*.srt 2>/dev/null

# 生成输出
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5]/_/g' | cut -c1-50)
OUTPUT_FILE="${OUTPUT_DIR}/${SAFE_TITLE}_${BVID}_transcript.txt"

cat > "$OUTPUT_FILE" << EOF
================================================================================
B站视频转录文档
================================================================================

📹 视频标题：$TITLE
🔗 B站链接：$VIDEO_URL
👤 作者：$AUTHOR
📅 发布时间：$UPLOAD_DATE_FORMATTED
⏱️  视频时长：$DURATION
📝 转录来源：$TRANSCRIPT_SOURCE
⏰ 转录时间：$(date '+%Y-%m-%d %H:%M:%S')

================================================================================
第一部分：视频摘要
================================================================================

【视频核心内容摘要请见下方】

================================================================================
第二部分：完整原文
================================================================================

$TRANSCRIPT_TEXT

================================================================================
文档结束
================================================================================
EOF

echo ""
echo "✅ 转录完成！"
echo "📄 文件: $OUTPUT_FILE"
echo ""
echo "$OUTPUT_FILE"
