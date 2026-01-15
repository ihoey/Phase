#!/bin/bash

# Phase 快速启动脚本

set -e

echo "🚀 Phase - macOS 代理工具"
echo ""

# 检查 sing-box
echo "🔍 检查 sing-box..."
if command -v sing-box &> /dev/null; then
    SINGBOX_PATH=$(which sing-box)
    echo "✅ 找到 sing-box: $SINGBOX_PATH"
else
    echo "⚠️  未找到 sing-box"
    echo ""
    echo "请安装 sing-box："
    echo "  brew install sing-box"
    echo ""
    echo "或从 https://github.com/SagerNet/sing-box/releases 下载"
    echo ""
    echo "Phase 会在以下路径查找 sing-box："
    echo "  - /usr/local/bin/sing-box"
    echo "  - /opt/homebrew/bin/sing-box"
    echo "  - /usr/bin/sing-box"
    echo "  - Resources/sing-box (App Bundle 内)"
    echo ""
fi

# 构建项目
echo ""
echo "🔨 构建项目..."
swift build

echo ""
echo "✨ 构建完成！"
echo ""
echo "运行应用："
echo "  swift run"
echo ""
echo "或在 Xcode 中打开："
echo "  open Package.swift"
echo ""
