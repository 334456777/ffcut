#!/bin/bash

# 输入文件名
input_file="input.mp4"
# 输出文件名
output_file="output.mp4"

# 检测静音部分并生成裁剪命令
silence_cmd=$(ffmpeg -i "$input_file" -af silencedetect=n=-40dB:d=0.000001 -f null - 2>&1 | awk '
  /silence_start/ { start=$5 }
  /silence_end/ { end=$5; print "between(t," start "," end ")"; }
' | awk '{ print "[" NR "]trim=" $0 "; [" NR "]setpts=PTS-STARTPTS" }' | tr '\n' ',' | sed 's/,$//')

# 生成并执行 ffmpeg 裁剪命令
ffmpeg -i "$input_file" -vf "select='not($(ffmpeg -i "$input_file" -af silencedetect=n=-40dB:d=0.000001 -f null - 2>&1 | awk '/silence_start/ { start=$5 } /silence_end/ { end=$5; print "between(t," start "," end ")"; }' | tr '\n' '+'))',setpts=N/FRAME_RATE/TB" -af "aselect='not($(ffmpeg -i "$input_file" -af silencedetect=n=-40dB:d=0.000001 -f null - 2>&1 | awk '/silence_start/ { start=$5 } /silence_end/ { end=$5; print "between(t," start "," end ")"; }' | tr '\n' '+'))',asetpts=N/SR/TB" -y "$output_file"

echo "处理完成，输出文件为 $output_file"
