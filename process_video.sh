#!/bin/bash

# 输入文件名
input_file="input.mp4"
# 输出文件名
output_file="output.mp4"

# 检测静音部分并生成裁剪命令
ffmpeg -i "$input_file" -af silencedetect=n=-40dB:d=0.000001 -f null - 2>&1 | awk '
  /silence_start/ { start=$5 }
  /silence_end/ { end=$5; print "between(t," start "," end ")"; }
' > silences.txt

# 如果没有静音部分，直接复制文件
if [ ! -s silences.txt ]; then
  cp "$input_file" "$output_file"
  echo "没有检测到静音部分，输出文件为 $output_file"
  exit 0
fi

# 生成过滤器字符串
filter_string=$(awk '{ print "[" NR "]trim=" $0 "; [" NR "]setpts=PTS-STARTPTS" }' silences.txt | tr '\n' ',' | sed 's/,$//')

# 生成并执行 ffmpeg 裁剪命令
ffmpeg -i "$input_file" -vf "select='not($(awk '{print $0}' silences.txt | tr '\n' '+'))',setpts=N/FRAME_RATE/TB" -af "aselect='not($(awk '{print $0}' silences.txt | tr '\n' '+'))',asetpts=N/SR/TB" -y "$output_file"

echo "处理完成，输出文件为 $output_file"

# 清理临时文件
rm silences.txt
