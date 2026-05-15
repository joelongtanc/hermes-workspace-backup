---
name: gzh-explosive-content-detector
description: 获取公众号热门文章数据，包含多个领域10w+文章，拆解流量密码。技能包含：根据用户输入的关键词，输出标题、作品链接、作者、发布时间、阅读数、推荐理由。
dependency:
  python:
    - requests>=2.28.0
  system:
---

# 公众号爆款雷达

触发本技能并需要执行完整流程时，**必须先读取**与本技能同目录下的 `references/gzh_explosive_content_workflow.md`，并**完整遵循**其中的核心执行规则、操作步骤（功能一各步骤及步骤7自检）与输出要求。数据格式说明见 `references/gzh_trend_data_format.md`。脚本路径相对于技能目录：`scripts/fetch_gzh_trends.py`。
