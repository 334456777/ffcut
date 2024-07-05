#!/bin/bash

# 检查参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_video> <input_image>"
    exit 1
fi

input_video="$1"
input_image="$2"
output_video="output.mp4"
output_audio="output.mp3"

# 检查输入文件是否存在
if [ ! -f "$input_video" ]; then
    echo "Error: Input video file '$input_video' does not exist."
    exit 1
fi

if [ ! -f "$input_image" ]; then
    echo "Error: Input image file '$input_image' does not exist."
    exit 1
fi

# 检查并安装 ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg not found. Installing ffmpeg..."
    sudo apt update
    sudo apt install -y ffmpeg
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install ffmpeg."
        exit 1
    fi
fi

# 运行 ffmpeg 命令
ffmpeg -i "$input_video" -loop 1 -t 1 -i "$input_image" -filter_complex \
"[0:a]silenceremove=stop_periods=-1:stop_threshold=-20dB[aout]; \
 [0:v]cropdetect=limit=24:round=2:reset=1, crop=iw:ih:iw-2*overlay_w/2:ih-2*overlay_h/2, format=yuva420p[video]; \
 [video]fade=t=in:st=0:d=1:alpha=1,fade=t=out:st=7:d=1:alpha=1[video_faded]; \
 [1:v]format=yuva420p,split[image_in][image_out]; \
 [image_in]fade=t=out:st=0:d=1:alpha=1[image_in_faded]; \
 [image_out]fade=t=in:st=0:d=1:alpha=1[image_out_faded]; \
 [image_in_faded][video_faded]overlay=eof_action=pass[part1]; \
 [part1][image_out_faded]overlay=eof_action=pass[final_video]" \
-map "[final_video]" -map aout -c:v libx264 -c:a aac "$output_video" \
-map aout -c:a libmp3lame -q:a 0 "$output_audio"

# 检查 ffmpeg 命令是否成功
if [ $? -ne 0 ]; then
    echo "Error: ffmpeg processing failed."
    exit 1
fi

echo "处理完成："
echo "视频文件: $output_video"
echo "音频文件: $output_audio"
