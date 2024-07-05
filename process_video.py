import ffmpeg
import re

def get_silence_timestamps(input_file):
    # FFmpeg command to detect silence
    probe = (
        ffmpeg
        .input(input_file)
        .output('pipe:', format='null')
        .global_args('-af', 'silencedetect=n=-30dB:d=0.000001')
        .run(capture_stderr=True)
    )
    
    stderr_output = probe[1].decode()
    
    # Extracting silence timestamps from FFmpeg output
    silence_start_pattern = re.compile(r'silence_start: (\d+\.\d+)')
    silence_end_pattern = re.compile(r'silence_end: (\d+\.\d+)')

    silence_start_times = []
    silence_end_times = []

    for line in stderr_output.split('\n'):
        start_match = silence_start_pattern.search(line)
        if start_match:
            silence_start_times.append(float(start_match.group(1)))

        end_match = silence_end_pattern.search(line)
        if end_match:
            silence_end_times.append(float(end_match.group(1)))

    # Combine start and end times into intervals
    silence_intervals = list(zip(silence_start_times, silence_end_times))

    return silence_intervals

def remove_silence(input_file, output_file):
    ffmpeg.input(input_file).output(output_file, af='silenceremove=stop_periods=-1:stop_duration=0.000001:stop_threshold=-30dB').run(overwrite_output=True)

# Example usage
input_video = 'input.mp4'
output_video = 'output.mp4'

silence_intervals = get_silence_timestamps(input_video)
remove_silence(input_video, output_video)

print("Silence intervals:", silence_intervals)
