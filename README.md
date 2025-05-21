# Aegisub Scripts

A collection of useful scripts for [Aegisub](http://www.aegisub.org/) to automate and enhance the subtitling workflow.

## 📜 Table of Contents

- [GlobalRotation](#-globalrotation)
- [Groupcopy](#-groupcopy)
- [Whispers](#-whispers)

## 🌐 GlobalRotation

**GlobalRotation** is a Lua script for Aegisub that allows you to rotate multiple subtitle lines around a specific origin point, while preserving each line’s original rotation.

### ✨ Features

- Rotate subtitle lines around a custom origin point.
- Recalculates each line's position and origin to simulate global rotation.

### ▶️ Usage

1. Select the subtitle lines you want to rotate.
2. Run the `GlobalRotation` script from the `Automation` menu.
3. Specify the origin point for rotation.
4. The script will apply rotation transformations relative to the chosen origin without altering the original org.

## 📋 Groupcopy

**Groupcopy** is a script that allows you to copy all start tags from N lines to N lines, with options to overwrite existing tags, keep inline tags, and preserve old start tags on the destination lines.

To use it properly, you must select all the lines **to copy from** and all the lines **to copy to**, separated by at least one commented line. To separate the groups, insert a comment line containing only:

```
--end
```

By default, new tags are added to the end of existing tags. If you enable the "Transform at the end of line" option, all transform tags will be moved to the end.

### ✨ Features

- **Copy start tags from 1 to N lines, repeated X times**

Example:

```
{\b1} (copy from)
{\fad(300,400)} (copy from)
--end (separator)
(first group of lines (1), \b will be copied here)
(first group of lines (2), \b will be copied here)
--end (separator)
(second group of lines (1), \fad(300,400) will be copied here)
(second group of lines (2), \fad(300,400) will be copied here)
(second group of lines (3), \fad(300,400) will be copied here)
```

- **Copy start tags from N to N lines, repeated X times**

Example:

```
{\b1} (copy from)
{\i1} (copy from)
--end (separator)
{\u1} (copy from)
{\s1} (copy from)
--end (separator)
(first group of lines (1-1), \b1 will be copied here)
(first group of lines (1-2), \i1 will be copied here)
--end (separator)
(second group of lines (2-1), \u1 will be copied here)
(second group of lines (1-1), \s1 will be copied here)
```

You can copy more than one tag for each group. Have fun!

## 🎧 Whispers

**Whispers** is a Lua script for Aegisub that automatically transcribes spoken audio from the selected subtitle lines using OpenAI Whisper.

It works by extracting audio clips based on each line’s timing and passing them to a standalone Whisper executable for transcription. The recognized text is then inserted directly into the subtitle line.

### ✨ Features

- Automatically extracts audio clips for selected lines.
- Sends clips to [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win) for transcription.
- Inserts transcribed text into the subtitle's text field.

### 📦 Requirements

- [**ffmpeg**](https://ffmpeg.org/download.html)
- [**whisper-standalone-win**](https://github.com/Purfview/whisper-standalone-win)

> ⚠️ **Both `ffmpeg` and `whisper-standalone.exe` must be available in your system's `PATH`.**
> After setting the PATH, **restart Aegisub** to apply the changes.

### 🛠️ Installation

1. Download `ghe.Whispers.lua` and place it in your automation folder.
2. Download and extract [ffmpeg](https://ffmpeg.org/download.html).
3. Download and extract [whisper-standalone-win](https://github.com/Purfview/whisper-standalone-win).
4. Make sure both `ffmpeg.exe` and `whisper-standalone.exe` are in your system `PATH`.
5. Restart Aegisub.

### ▶️ Usage

1. Open a video or audio file in Aegisub.
2. Select one or more subtitle lines.
3. Run the script via `Automation` → `Whispers`.
4. Transcribed text will be automatically inserted into the selected lines.

### 📝 Notes

- The script creates temporary WAV files in the script's directory.
- Make sure you have sufficient disk space for temporary files.
- Processing time depends on the length of selected clips and your hardware.
