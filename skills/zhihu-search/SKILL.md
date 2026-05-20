---
name: zhihu-search
description: Search知乎内容（搜索问题、回答、文章）。当用户说"搜索知乎"、"知乎"、"查知乎"、"搜一下知乎"时触发。也用于回答涉及知乎内容的问题或需要引用知乎答案的场景。
metadata: {"clawdbot":{"emoji":"🔍","requires":{"env":["ZHIHU_ACCESS_SECRET"]},"primaryEnv":"ZHIHU_ACCESS_SECRET"}}
---

# 知乎搜索 Skill

使用知乎开放平台 API 进行内容搜索，支持知乎搜索(`zhihu_search`)和全网搜索(`global_search`)。

## 环境变量

- `ZHIHU_ACCESS_SECRET`: 知乎开放平台的 Access Secret（Bearer Token）
  - 在 https://developer.zhihu.com/apps 個人中心查看
  - 示例: `3b60f3981efa13ff70dd091fe6c8d4f7c5d55ba6`

## API 接口

| 接口 | 端点 | 说明 |
|------|------|------|
| 知乎搜索 | `https://developer.zhihu.com/api/v1/content/zhihu_search` | 搜索知乎站内内容 |
| 全网搜索 | `https://developer.zhihu.com/api/v1/content/global_search` | 搜索全网内容 |

## 使用方式

直接调用脚本:

```bash
# 知乎搜索
node {baseDir}/scripts/search.mjs "查询内容" zhihu

# 全网搜索
node {baseDir}/scripts/search.mjs "查询内容" global

# 指定返回数量
node {baseDir}/scripts/search.mjs "查询内容" zhihu 10
```

## 请求说明

- 鉴权方式: `Authorization: Bearer <ZHIHU_ACCESS_SECRET>`
- 时间戳头: `X-Request-Timestamp` (秒级 Unix 时间戳)
- Content-Type: `application/json`
- 查询参数: `query` (URL encode)

## 输出格式

返回 JSON 格式的搜索结果，包含标题、链接、摘要等信息。

## 注意事项

- 如遇 401 错误，检查 `ZHIHU_ACCESS_SECRET` 是否有效
- 知乎搜索优先站内内容，全网搜索覆盖更广
- 查询词建议简洁精准，避免过长