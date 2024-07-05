package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"sync"
)

type Silence struct {
	Start float64
	End   float64
}

func main() {
	// Step 1: Detect silence
	err := detectSilence("input.mp4", "silence.log")
	if err != nil {
		fmt.Println("Error detecting silence:", err)
		return
	}

	// Step 2: Parse silence.log
	silences, err := parseSilenceLog("silence.log")
	if err != nil {
		fmt.Println("Error parsing silence log:", err)
		return
	}

	// Step 3: Generate ffmpeg commands and process them concurrently
	err = generateAndExecuteCommands(silences, "input.mp4", "output.mp4")
	if err != nil {
		fmt.Println("Error processing video:", err)
		return
	}
}

func detectSilence(inputFile, logFile string) error {
	cmd := exec.Command("ffmpeg", "-i", inputFile, "-af", "silencedetect=n=-50dB:d=2", "-f", "null", "-")
	cmd.Stderr = &logWriter{file: logFile}
	return cmd.Run()
}

type logWriter struct {
	file string
}

func (writer *logWriter) Write(p []byte) (n int, err error) {
	f, err := os.OpenFile(writer.file, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	if _, err := f.Write(p); err != nil {
		return 0, err
	}
	return len(p), nil
}

func parseSilenceLog(logFile string) ([]Silence, error) {
	file, err := os.Open(logFile)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var silences []Silence
	reStart := regexp.MustCompile(`silence_start: (\d+\.\d+)`)
	reEnd := regexp.MustCompile(`silence_end: (\d+\.\d+)`)
	scanner := bufio.NewScanner(file)

	var start float64
	for scanner.Scan() {
		line := scanner.Text()
		if matches := reStart.FindStringSubmatch(line); matches != nil {
			start, _ = strconv.ParseFloat(matches[1], 64)
		}
		if matches := reEnd.FindStringSubmatch(line); matches != nil {
			end, _ := strconv.ParseFloat(matches[1], 64)
			silences = append(silences, Silence{Start: start, End: end})
		}
	}

	return silences, scanner.Err()
}

func generateAndExecuteCommands(silences []Silence, inputFile, outputFile string) error {
	start := 0.0
	var tempFiles []string
	var wg sync.WaitGroup
	sem := make(chan struct{}, 4) // 控制并发数

	for i, silence := range silences {
		partFile := fmt.Sprintf("part%d.mp4", i)
		tempFiles = append(tempFiles, partFile)
		wg.Add(1)
		sem <- struct{}{}
		go func(start, end float64, partFile string) {
			defer wg.Done()
			defer func() { <-sem }()
			err := executeFFmpegCommand(inputFile, start, end, partFile)
			if err != nil {
				fmt.Println("Error executing ffmpeg command:", err)
			}
		}(start, silence.Start, partFile)
		start = silence.End
	}

	// Add the last segment
	partFile := fmt.Sprintf("part%d.mp4", len(silences))
	tempFiles = append(tempFiles, partFile)
	wg.Add(1)
	sem <- struct{}{}
	go func(start float64, partFile string) {
		defer wg.Done()
		defer func() { <-sem }()
		err := executeFFmpegCommand(inputFile, start, -1, partFile)
		if err != nil {
			fmt.Println("Error executing ffmpeg command:", err)
		}
	}(start, partFile)

	wg.Wait()

	// Create input.txt for concat
	inputTxt := "input.txt"
	file, err := os.Create(inputTxt)
	if err != nil {
		return err
	}
	defer file.Close()

	for _, tempFile := range tempFiles {
		file.WriteString(fmt.Sprintf("file '%s'\n", tempFile))
	}

	// Concatenate all parts
	cmd := exec.Command("ffmpeg", "-f", "concat", "-safe", "0", "-i", inputTxt, "-c", "copy", outputFile)
	err = cmd.Run()
	if err != nil {
		return err
	}

	// Clean up temporary files
	for _, tempFile := range tempFiles {
		os.Remove(tempFile)
	}
	os.Remove(inputTxt)
	return nil
}

func executeFFmpegCommand(inputFile string, start, end float64, outputFile string) error {
	args := []string{"-i", inputFile, "-ss", fmt.Sprintf("%f", start), "-c", "copy"}
	if end > 0 {
		args = append(args, "-to", fmt.Sprintf("%f", end))
	}
	args = append(args, outputFile)
	cmd := exec.Command("ffmpeg", args...)
	return cmd.Run()
}
