# ass-whispers

**ass-whispers** is a tool for transciption builded for **Aegisub** macro **Whispers**.

## GPU

GPU execution requires the following NVIDIA libraries to be installed:

- [cuBLAS for CUDA 12](https://developer.nvidia.com/cublas)
- [cuDNN 9 for CUDA 12](https://developer.nvidia.com/cudnn)

## Usage

ass-whispers [-h] [--device DEVICE] [--model MODEL]
[--language LANGUAGE] [--version]
audio timestamps
ass-whispers \<audio_file> \<timestamps_file> [-h] [--device DEVICE] [--model MODEL] [--language LANGUAGE] [--version]

## Timestamps File Format

The timestamps_file should be a JSON file like this:

```
[
  {"start_time": 1234, "end_time": 5678},
  {"start_time": 9100, "end_time": 11234}
]
```

Developed by Ghegghe.
