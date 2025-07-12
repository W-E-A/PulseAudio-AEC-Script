#!/bin/bash
#
# PulseAudio AEC 自动配置脚本 - 卸载程序
#
# 此脚本用于从用户配置文件中移除AEC设置。
#

# --- 全局变量 ---
PULSE_USER_CONFIG_DIR="$HOME/.config/pulse"
PULSE_USER_CONFIG_FILE="$PULSE_USER_CONFIG_DIR/default.pa"
AEC_COMMENT="# Added by AEC setup script"

# --- 脚本主逻辑 ---
echo "正在卸载PulseAudio AEC配置..."

# 检查用户配置文件是否存在
if [ ! -f "$PULSE_USER_CONFIG_FILE" ]; then
    echo "未找到用户配置文件 '$PULSE_USER_CONFIG_FILE'，无需执行任何操作。"
    exit 0
fi

# 检查是否包含我们的配置
if ! grep -q "$AEC_COMMENT" "$PULSE_USER_CONFIG_FILE"; then
    echo "在用户配置文件中未找到AEC配置，无需执行任何操作。"
    exit 0
fi

# 从用户配置文件中删除我们添加的行
sed -i "/^${AEC_COMMENT}/,/\(set-default-source echoCancel_source\)/d" "$PULSE_USER_CONFIG_FILE"

echo "AEC配置已从 '$PULSE_USER_CONFIG_FILE' 移除。"
echo "正在重启PulseAudio以应用更改..."
pulseaudio -k
sleep 1
echo "卸载完成。"

exit 0