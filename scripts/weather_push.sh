#!/bin/bash
# 海珠区天气预报推送脚本

# 获取当前天气
current=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=%l:+%c+%t+湿度%h+%w")

# 获取当天分小时预报 (00:00-23:00 每3小时)
hourly=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=1" | head -1)

# 获取完整预报信息
forecast=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=%C,温度%t,湿度%h,风力%w" | head -1)

# 获取最高/最低温度
range=$(curl -s "wttr.in/Haizhu+Guangzhou?lang=zh&format=高%H°C/低%L°C" | head -1)

# 构建消息
message="🌤️ 海珠区天气预报

📍 当前：${current}
🌡️ 温度范围：${range}
📝 概况：${forecast}

⏰ 更新时间：$(date '+%Y-%m-%d %H:%M')"

# 发送到企业微信群
openclaw message send \
  --channel wecom \
  --target wremyohwaa_snnbiqaeny9jkwunmecdq \
  --message "$message"
