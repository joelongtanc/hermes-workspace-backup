name: github-proxy
description: GitHub 代理备用出口 - 当本地直连失败时自动通过美国服务器代理访问 GitHub
category: devops

commands:
  start_proxy: |
    # 启动 GitHub SOCKS5 代理隧道
    # 美国服务器: 186.244.210.52:8232
    ssh -fN -D 127.0.0.1:10808 \
      -o StrictHostKeyChecking=no \
      -o ServerAliveInterval=30 \
      -p 8232 root@186.244.210.52

  test_proxy: |
    # 测试代理是否工作
    curl --socks5 127.0.0.1:10808 --max-time 10 https://api.github.com/zen

  git_via_proxy: |
    # Git 走代理 clone
    git clone --depth 1 https://github.com/jgm/pandoc.git

tools:
  proxy_port: 10808
  remote_server: 186.244.210.52
  remote_port: 8232
  remote_user: root

notes: |
  - 代理通过 SSH -D 建立 SOCKS5 隧道
  - Git 已全局配置使用代理: git config --global http.https://github.com.proxy socks5://127.0.0.1:10808
  - 注意: 经代理速度比直连慢好多，只有直连失败时才用
