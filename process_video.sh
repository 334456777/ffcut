#!/bin/bash

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video>"
    exit 1
fi

input_video="$1"
output_video="output.mp4"

# 使用复杂过滤器去除静音片段并合并剩下的部分
ffmpeg -i "$input_video" -vf "select='gt(scene,0.4)',setpts=N/FRAME_RATE/TB" -af "silenceremove=stop_periods=-1:stop_threshold=40dB:detection=peak,aresample=async=1" -c:v copy -c:a copy "$output_video"
if [ $? -ne 0 ]; then
    echo "Error: Failed to remove silence."
    exit 1
fi

echo "处理完成："
echo "视频文件: $output_video"
