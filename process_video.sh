#!/bin/bash

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video>"
    exit 1
fi

input_video="$1"
output_video="output.mp4"
silent_duration="1"  # 将此值修改为所需的静音部分持续时间（单位：秒）

# 步骤: 去除静音部分
ffmpeg -i "$input_video" -af "silenceremove=stop_periods=-1:stop_duration=${silent_duration}:stop_threshold=-20dB" -c:v copy "$output_video"
if [ $? -ne 0 ]; then
    echo "Error: Failed to remove silence."
    exit 1
fi

# 清理输入文件
rm "$input_video"

echo "处理完成："
echo "视频文件: $output_video"
