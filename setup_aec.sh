#!/bin/bash
#
# PulseAudio AEC 自动配置脚本 - 安装程序
#
# 此版本完全在用户空间内操作，无需sudo权限，更安全、更简洁。
#

# --- 全局变量 ---
PULSE_USER_CONFIG_DIR="$HOME/.config/pulse"
PULSE_USER_CONFIG_FILE="$PULSE_USER_CONFIG_DIR/default.pa"
PULSE_SYSTEM_CONFIG_FILE="/etc/pulse/default.pa"
AEC_COMMENT="# Added by AEC setup script"

# --- 函数定义 ---

# 检查并准备用户配置文件
function prepare_user_config() {
    if [ ! -f "$PULSE_USER_CONFIG_FILE" ]; then
        echo "未找到用户配置文件，将从系统模板创建..."
        mkdir -p "$PULSE_USER_CONFIG_DIR"
        cp "$PULSE_SYSTEM_CONFIG_FILE" "$PULSE_USER_CONFIG_FILE"
        echo "已创建用户配置文件: $PULSE_USER_CONFIG_FILE"
    fi
}

# --- 脚本主逻辑 ---
echo "欢迎使用PulseAudio AEC自动配置脚本 (用户空间版)。"

# 1. 检查并准备配置文件
prepare_user_config

# 2. 获取并选择输入设备
echo "正在检测可用的输入设备..."
mapfile -t sources < <(pactl list sources short | awk '{print $2}')
if [ ${#sources[@]} -eq 0 ]; then
  echo "错误：未找到任何输入设备。请检查 'pactl list sources short' 命令。"
  exit 1
fi

echo "请选择一个麦克风作为AEC的主设备 (推荐使用USB麦克风):"
select source_name in "${sources[@]}"; do
  if [[ -n "$source_name" ]]; then
    break
  else
    echo "无效的选择，请重新输入。"
  fi
done
echo "你选择了: $source_name"

# 3. 准备要添加的配置
AEC_CONFIG_LINES="
$AEC_COMMENT
load-module module-echo-cancel aec_method=webrtc source_master=$source_name source_name=echoCancel_source
set-default-source echoCancel_source
"

# 4. 写入用户配置文件
echo "正在将配置写入您的用户配置文件: $PULSE_USER_CONFIG_FILE"
# 先删除旧的配置，防止重复添加
sed -i "/^${AEC_COMMENT}/,/\(set-default-source echoCancel_source\)/d" "$PULSE_USER_CONFIG_FILE"
# 追加新配置
echo "$AEC_CONFIG_LINES" >> "$PULSE_USER_CONFIG_FILE"
echo "配置写入成功！"

# 5. 重启PulseAudio以加载新配置
echo "正在重启PulseAudio服务以应用更改..."
pulseaudio -k
sleep 1 # 等待服务重启
echo "脚本执行完毕！"
echo "请前往你的系统声音设置，将输入设备选择为含有 'with Echo Cancellation' 字样的虚拟设备。"

exit 0