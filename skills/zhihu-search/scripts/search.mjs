#!/usr/bin/env node

/**
 * 知乎搜索脚本
 * 用法: node search.mjs "查询内容" [zhihu|global] [数量]
 */

const ACCESS_SECRET = process.env.ZHIHU_ACCESS_SECRET;
const ZHIHU_SEARCH_API = 'https://developer.zhihu.com/api/v1/content/zhihu_search';
const GLOBAL_SEARCH_API = 'https://developer.zhihu.com/api/v1/content/global_search';

function usage() {
  console.log('用法: node search.mjs "查询内容" [zhihu|global] [数量]');
  console.log('示例: node search.mjs "机器学习" zhihu 5');
  console.log('      node search.mjs "AI发展趋势" global 10');
}

async function search(query, type = 'zhihu', limit = 5) {
  if (!ACCESS_SECRET) {
    console.error('错误: 未设置 ZHIHU_ACCESS_SECRET 环境变量');
    console.error('请在知乎开放平台获取 Access Secret: https://developer.zhihu.com/apps');
    process.exit(1);
  }

  const apiUrl = type === 'global' ? GLOBAL_SEARCH_API : ZHIHU_SEARCH_API;
  const timestamp = Math.floor(Date.now() / 1000);

  const url = `${apiUrl}?Query=${encodeURIComponent(query)}`;

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${ACCESS_SECRET}`,
        'X-Request-Timestamp': String(timestamp),
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      if (response.status === 401) {
        console.error('错误: 知乎 API 认证失败，请检查 ZHIHU_ACCESS_SECRET 是否有效');
      } else {
        console.error(`错误: API 返回状态码 ${response.status}`);
      }
      const errorText = await response.text();
      console.error('响应:', errorText);
      process.exit(1);
    }

    const data = await response.json();
    console.log(JSON.stringify(data, null, 2));

  } catch (error) {
    console.error('请求失败:', error.message);
    process.exit(1);
  }
}

const args = process.argv.slice(2);

if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
  usage();
  process.exit(0);
}

const query = args[0];
const type = args[1] || 'zhihu';
const limit = parseInt(args[2]) || 5;

if (!['zhihu', 'global'].includes(type)) {
  console.error('错误: 类型必须是 zhihu 或 global');
  usage();
  process.exit(1);
}

search(query, type, limit).catch(err => {
  console.error('执行失败:', err);
  process.exit(1);
});