#!/bin/bash

# 企业微信应用消息推送
CORP_ID="wwe7da08439a9c9cb8"
BOT_ID="aibr3LD7R-d7PmAgS235Ga17PnrnR_yzRS9"
BOT_SECRET="hrJp8G6oEo7U4wjGU8FZKbrPgWcJiIJaqis4tzgFDTv"
TARGET="wremyohwaa_snnbiqaeny9jkwunmecdq"

# 获取 access_token
TOKENResp=$(curl -s "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CORP_ID&corpsecret=$BOT_SECRET")
ACCESS_TOKEN=$(echo $TOKENResp | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "获取token失败: $TOKENResp"
  exit 1
fi

# 获取天气数据
current=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=%l:+%c+%t+湿度%h+%w")
range=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=高%H°C/低%L°C" | head -1)

# 构建消息
MSG="🌤️ 海珠区天气预报

📍 当前：${current}
🌡️ 温度范围：${range}
⏰ 更新时间：$(date '+%Y-%m-%d %H:%M')"

# 发送消息到群聊
curl -s "https://qyapi.weixin.qq.com/cgi-bin/appchat/send?access_token=$ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"chatid\":\"$TARGET\",\"msgtype\":\"text\",\"text\":{\"content\":\"$MSG\"}}"
