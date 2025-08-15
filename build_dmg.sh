#!/bin/bash

# 一键构建和打包AppBar应用为dmg文件

# 检查是否在正确的目录中
if [ ! -f "Package.swift" ]; then
  echo "错误：请在项目根目录中运行此脚本"
  exit 1
fi

echo "开始构建AppBar应用..."

# 清理之前的构建
echo "清理之前的构建..."
rm -rf .build/
rm -rf AppBar.app/
rm -f AppBar.dmg

# 构建项目
echo "正在构建项目..."
swift build -c release --product AppBar
if [ $? -ne 0 ]; then
  echo "错误：项目构建失败"
  exit 1
fi

# 创建.app包结构
echo "创建.app包结构..."
mkdir -p AppBar.app/Contents/MacOS
cp .build/release/AppBar AppBar.app/Contents/MacOS/
cp Info.plist AppBar.app/Contents/

# 检查create-dmg是否已安装
echo "检查create-dmg是否已安装..."
if ! command -v create-dmg &> /dev/null; then
  echo "create-dmg未找到，正在安装..."
  brew install create-dmg
  if [ $? -ne 0 ]; then
    echo "错误：create-dmg安装失败"
    exit 1
  fi
else
  echo "create-dmg已安装"
fi

# 创建dmg文件
echo "正在创建dmg文件..."
create-dmg \
  --volname "AppBar" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  AppBar.dmg \
  AppBar.app

if [ $? -ne 0 ]; then
  echo "错误：dmg文件创建失败"
  exit 1
fi

# 检查dmg文件是否创建成功
if [ ! -f "AppBar.dmg" ]; then
  echo "错误：dmg文件未找到"
  exit 1
fi

echo "成功创建dmg文件：$(pwd)/AppBar.dmg"
rm -rf AppBar.app/

# 显示文件信息
ls -lh AppBar.dmg

echo "构建和打包完成！"