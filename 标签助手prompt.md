#!/bin/bash

# 检查并创建部署目录
if [ ! -d "/root/base" ]; then
    echo "创建部署目录 /root/base ..."
    mkdir -p /root/base
fi

# 检查压缩包是否存在
if [ ! -f "/root/base/xiaoyi_server.tar.gz" ]; then
    echo "错误：压缩包 xiaoyi_server.tar.gz 不存在于 /root/base 目录"
    echo "请先上传压缩包再运行此脚本"
    exit 1
fi

# 进入部署目录
cd /root/base || {
    echo "错误：无法进入 /root/base 目录"
    exit 1
}

# 清理旧的部署文件（保留旧的可执行文件）
echo "清理旧文件..."
find . -maxdepth 1 ! -name 'xiaoyi_server.tar.gz' ! -name '.' ! -name '..' ! -name 'xiaoyi_server' -exec rm -rf {} +

# 解压新上传的代码
echo "解压代码..."
tar -xzf xiaoyi_server.tar.gz || {
    echo "错误：解压失败"
    exit 1
}

echo "开始编译项目..."
go build -o xiaoyi_server.new || {
    echo "错误：编译失败"
    exit 1
}

# 赋予执行权限
chmod +x xiaoyi_server.new || {
    echo "错误：无法设置执行权限"
    exit 1
}

# 创建日志目录
mkdir -p logs

# --- 优雅关闭服务的修正逻辑 ---
# 1. 先找到旧服务的PID
old_pid=$(pgrep -f "xiaoyi_server")

# 2. 判断PID是否存在，然后执行关闭逻辑
if [ ! -z "$old_pid" ]; then
    echo "发现旧服务进程，进程ID: $old_pid，正在尝试优雅关闭..."
    kill -15 $old_pid
    # 等待最多10秒让其自行退出
    timeout=10
    while kill -0 $old_pid 2>/dev/null && [ $timeout -gt 0 ]; do
        sleep 1
        timeout=$((timeout-1))
    done

    # 如果还在运行，则强制杀死
    if kill -0 $old_pid 2>/dev/null; then
        echo "优雅关闭超时，正在强制结束进程..."
        kill -9 $old_pid
    else
        echo "旧服务已成功关闭。"
    fi
else
    echo "未发现正在运行的旧服务。"
fi
# --- 修正结束 ---

# 替换旧的可执行文件
mv -f xiaoyi_server.new xiaoyi_server

# --- 启动服务的修正逻辑 ---
echo "启动服务..."
# 只需要一条启动命令，将标准输出(stdout)和标准错误(stderr)都重定向到app.log
nohup ./xiaoyi_server >> logs/app.log 2>&1 &
# --- 修正结束 ---

# 等待几秒检查服务是否正常启动
sleep 3
if pgrep -f "xiaoyi_server" > /dev/null; then
    echo "服务启动成功！"
    echo "应用日志位置: logs/app.log"
else
    echo "服务可能启动失败，请检查日志文件"
    echo "最后10行应用日志："
    tail -n 10 logs/app.log
fi