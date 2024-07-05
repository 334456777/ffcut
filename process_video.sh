#!/bin/bash

# 检查参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video>"
    exit 1
fi

ffmpeg -i input.mp4 -af silenceremove=stop_periods=-1:stop_duration=0.000001:stop_threshold=-30dB -y output.mp4
if [ $? -ne 0 ]; then
    echo "Error: Failed to remove silence."
    exit 1
fi
