#!/bin/bash

# AI创作喵网站部署脚本
# 使用方法: ./deploy.sh [服务器地址] [用户名] [目标目录]

echo "========================================="
echo "  AI创作喵网站部署脚本"
echo "========================================="
echo ""

# 检查参数
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "使用方法: ./deploy.sh [服务器地址] [用户名] [目标目录]"
    echo "示例: ./deploy.sh example.com root /var/www/html"
    echo ""
    echo "或者使用 FTP/SFTP 客户端手动上传 website-deploy/ 目录下的所有文件"
    exit 1
fi

SERVER=$1
USER=$2
TARGET_DIR=$3

echo "准备部署到: $USER@$SERVER:$TARGET_DIR"
echo ""

# 检查文件是否存在
if [ ! -f "index.html" ]; then
    echo "错误: 找不到 index.html 文件"
    echo "请确保在 website-deploy/ 目录下运行此脚本"
    exit 1
fi

# 使用 rsync 上传（推荐）
if command -v rsync &> /dev/null; then
    echo "使用 rsync 上传文件..."
    rsync -avz --progress \
        --exclude='.DS_Store' \
        --exclude='*.sh' \
        --exclude='README.md' \
        --exclude='部署指南.md' \
        ./ $USER@$SERVER:$TARGET_DIR/
    echo ""
    echo "✅ 部署完成！"
    echo "请访问: https://hujiaofenwritingcat.top"
else
    echo "rsync 未安装，请使用 FTP/SFTP 客户端手动上传"
    echo "或安装 rsync: brew install rsync (macOS) 或 apt-get install rsync (Linux)"
fi
