#!/bin/bash

# 输入文件名
input_file="input.mp4"
# 输出文件名
output_file="output.mp4"
# 临时文件名
silence_log="silence.log"
silences_txt="silences.txt"

# 检测静音部分并生成时间戳文件
ffmpeg -i "$input_file" -af silencedetect=n=-40dB:d=0.000001 -f null - 2> "$silence_log"

# 解析时间戳文件并生成裁剪命令
awk '/silence_start/ { start=$5 } /silence_end/ { end=$5; print start "," end; }' "$silence_log" > "$silences_txt"

# 如果没有静音部分，直接复制文件
if [ ! -s "$silences_txt" ]; then
  cp "$input_file" "$output_file"
  echo "没有检测到静音部分，输出文件为 $output_file"
  exit 0
fi

# 创建一个过滤器文件
filter_file="filters.txt"
echo "" > "$filter_file"

# 遍历每个静音段并生成相应的过滤器
while read -r start end; do
  echo "trim=start_frame=$start:end_frame=$end,setpts=PTS-STARTPTS" >> "$filter_file"
done < "$silences_txt"

# 使用生成的过滤器文件进行裁剪
ffmpeg -i "$input_file" -filter_complex_script "$filter_file" -y "$output_file"

echo "处理完成，输出文件为 $output_file"
