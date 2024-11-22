#!/bin/bash

# 输入视频文件
input_file="input.mp4"
output_file="output.mp4"
silence_log="silence_log.txt"

# 设置静音阈值和持续时间
silence_threshold="-40dB"  # 设置静音阈值
silence_duration=0.5      # 设置静音持续时间

# 1. 检测静音部分
ffmpeg -i "$input_file" -af "silencedetect=n=$silence_threshold:d=$silence_duration" -f null - 2> "$silence_log"

# 2. 解析日志文件以获取静音时间戳
silence_segments=()
total_silence_duration=0  # 初始化静音总时长

while IFS= read -r line; do
    if [[ $line == *"silence_start:"* ]]; then
        start=$(echo "$line" | grep -oP 'silence_start: \K[0-9.]+')
        silence_segments+=("$start")
    fi
    if [[ $line == *"silence_end:"* ]]; then
        end=$(echo "$line" | grep -oP 'silence_end: \K[0-9.]+')
        silence_segments+=("$end")
        # 计算当前静音片段的时长
        start_time=${silence_segments[-2]}  # silence_start
        end_time=${silence_segments[-1]}    # silence_end
        duration=$(echo "$end_time - $start_time" | bc)
        total_silence_duration=$(echo "$total_silence_duration + $duration" | bc)
    fi
done < "$silence_log"

# 统计静音片段数量
num_silence_segments=$(( ${#silence_segments[@]} / 2 ))

# 输出静音片段数量和总时长
echo "静音片段数量: $num_silence_segments"
echo "静音片段总时长: $total_silence_duration 秒"

# 3. 用户选择是否继续
read -p "是否继续去除静音片段并渲染新视频? (y/n): " user_choice
if [[ "$user_choice" != "y" && "$user_choice" != "Y" ]]; then
    echo "操作已取消。"
    rm "$silence_log"
    exit 0
fi

# 4. 创建 ffmpeg 命令
filter_complex=""
map_parts=()
num_segments=${#silence_segments[@]}
segment_count=$((num_segments / 2))

# 构造过滤器
prev_end=0
for ((i=0; i<segment_count; i++)); do
    start_time=${silence_segments[$((i * 2))]}
    end_time=${silence_segments[$((i * 2 + 1))]}
    
    # 添加非静音片段到过滤器
    if (( $(echo "$prev_end < $start_time" | bc -l) )); then
        filter_complex+="[0:v]trim=$prev_end:$start_time,setpts=PTS-STARTPTS[v$i]; "
        filter_complex+="[0:a]atrim=$prev_end:$start_time,asetpts=PTS-STARTPTS[a$i]; "
        map_parts+=("[v$i]" "[a$i]")
    fi
    prev_end=$end_time
done

# 添加最后一个非静音片段
if (( $(echo "$prev_end < $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")" | bc -l) )); then
    filter_complex+="[0:v]trim=$prev_end,setpts=PTS-STARTPTS[v$segment_count]; "
    filter_complex+="[0:a]atrim=$prev_end,asetpts=PTS-STARTPTS[a$segment_count]; "
    map_parts+=("[v$segment_count]" "[a$segment_count]")
fi

# 5. 构建完整的命令
filter_complex+="$(IFS=; echo "${map_parts[*]}")concat=n=$((${#map_parts[@]} / 2)):v=1:a=1[outv][outa]"
ffmpeg -i "$input_file" -filter_complex "$filter_complex" -map "[outv]" -map "[outa]" "$output_file"

# 清理临时文件
rm "$silence_log"
