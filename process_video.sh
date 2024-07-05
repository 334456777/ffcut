#!/bin/bash

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video>"
    exit 1
fi

input_video="$1"
output_video="output.mp4"

# 步骤: 去除静音部分
ffmpeg -i "$input_video" -af silenceremove=start_periods=1:stop_periods=-1:stop_duration=0.2:start_threshold=-45dB:stop_threshold=-45dB "$output_video"
if [ $? -ne 0 ]; then
    echo "Error: Failed to remove silence."
    exit 1
fi
