#!/bin/bash
ffmpeg -i input.mp4 -af silenceremove=stop_periods=-1:stop_duration=0.000001:stop_threshold=-30dB -y output.mp4
if [ $? -ne 0 ]; then exit 1 fi
