#!/bin/bash

input_file=$1
output_file="output.mp4"

# Step 1: Detect silence and save the log
ffmpeg -i "$input_file" -af silencedetect=n=-50dB:d=2 -f null - 2> silence_log.txt

# Step 2: Parse the log to find non-silent segments
segments=()
last_end=0
while read -r line; do
  if [[ $line == *"silence_start"* ]]; then
    silence_start=$(echo $line | grep -oP '(?<=silence_start: )[^ ]+')
    if (( $(echo "$silence_start > $last_end" | bc -l) )); then
      segments+=("-ss $last_end -to $silence_start")
    fi
  elif [[ $line == *"silence_end"* ]]; then
    last_end=$(echo $line | grep -oP '(?<=silence_end: )[^ ]+')
  fi
done < silence_log.txt

# Include the final segment after the last silence
duration=$(ffmpeg -i "$input_file" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
if (( $(echo "$duration > $last_end" | bc -l) )); then
  segments+=("-ss $last_end")
fi

# Step 3: Extract and concatenate segments
counter=0
temp_files=()
for segment in "${segments[@]}"; do
  temp_file="temp_part_$counter.mp4"
  ffmpeg -y -i "$input_file" $segment -c copy "$temp_file"
  temp_files+=("$temp_file")
  counter=$((counter + 1))
done

# Create concat file
concat_file="concat_list.txt"
for f in "${temp_files[@]}"; do
  echo "file '$f'" >> "$concat_file"
done

# Merge segments
ffmpeg -y -f concat -safe 0 -i "$concat_file" -c copy "$output_file"

# Clean up
rm "${temp_files[@]}" "$concat_file" silence_log.txt
