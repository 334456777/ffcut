#!/bin/bash

# 检查参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_video> <input_image>"
    exit 1
fi

input_video="$1"
input_image="$2"

# 获取裁剪参数
crop_params=$(ffmpeg -i "$input_video" -vf "cropdetect=limit=24:round=2:reset=1" -f null - 2>&1 | grep crop | tail -1 | sed 's/.*crop=\([^ ]*\).*/\1/')

# 合并命令：去除静音、去除黑边、添加淡入淡出、添加图片和高斯模糊过渡
ffmpeg -i "$input_video" -loop 1 -t 1 -i "$input_image" -filter_complex \
"[0:a]silenceremove=stop_periods=-1:stop_threshold=-40dB:detection=peak[a]; \
 [0:v]crop=${crop_params},fade=in:0:30,fade=out:870:30[video]; \
 [1:v]format=yuva420p,fade=t=out:st=0:d=1:alpha=1[image_in]; \
 [video]format=yuva420p[main]; \
 [main]fade=t=in:st=0:d=1:alpha=1[image_out]; \
 [image_in][main]overlay=eof_action=pass[part1]; \
 [part1][image_out]overlay=eof_action=pass[final]" \
-map "[final]" -map "[a]" -c:v libx264 -c:a aac -strict experimental output.mp4
if [ $? -ne 0 ]; then
    echo "Error: Failed to process video."
    exit 1
fi

# 分离音频
ffmpeg -i output.mp4 -q:a 0 -map a output.mp3
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract audio."
    exit 1
fi

echo "处理完成："
echo "视频文件: output.mp4"
echo "音频文件: output.mp3"
