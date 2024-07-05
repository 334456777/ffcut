#!/bin/bash

# 检查参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_video> <input_image>"
    exit 1
fi

input_video="$1"
input_image="$2"

# 步骤 1: 去除静音部分
ffmpeg -i "$input_video" -af "silenceremove=stop_periods=-1:stop_threshold=-20dB" -c:v copy temp1.mp4

# 步骤 2: 去除黑边
ffmpeg -i temp1.mp4 -vf "crop=iw:ih:iw-2*overlay_w/2:ih-2*overlay_h/2" -c:a copy temp2.mp4

# 步骤 3: 添加淡入淡出效果
ffmpeg -i temp2.mp4 -vf "fade=in:0:30,fade=out:870:30" -c:a copy temp3.mp4

# 步骤 4: 添加图片和高斯模糊过渡
ffmpeg -loop 1 -t 1 -i "$input_image" -i temp3.mp4 -filter_complex \
"[0:v]format=yuva420p,fade=t=out:st=0:d=1:alpha=1[image_in]; \
 [1:v]format=yuva420p[video]; \
 [2:v]format=yuva420p,fade=t=in:st=0:d=1:alpha=1[image_out]; \
 [image_in][video]overlay=eof_action=pass[part1]; \
 [part1][image_out]overlay=eof_action=pass[final]" \
-map "[final]" -c:v libx264 -c:a aac output.mp4

# 步骤 5: 分离音频
ffmpeg -i output.mp4 -q:a 0 -map a output.mp3

# 清理临时文件
rm temp1.mp4 temp2.mp4 temp3.mp4

echo "处理完成："
echo "视频文件: output.mp4"
echo "音频文件: output.mp3"
