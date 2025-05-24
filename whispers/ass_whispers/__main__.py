import argparse
import os
import json
from typing import Literal, Optional, Union, List, Tuple
from faster_whisper import WhisperModel

# -m large-v2
# -d cuda
# --compute_type \"float32\"
# --task transcribe
# --language ja
# --temperature 0.4
# --best_of 8
# --beam_size 10
# --patience 2
# --repetition_penalty 1.4
# --condition_on_previous_text False
# --no_speech_threshold 0.275
# --logprob_threshold -1
# --compression_ratio_threshold 1.75
# --word_timestamp True
# --vad_filter True
# --vad_method pyannote_v3
# --sentence
# --standard_asia"

__version__ = "0.2.0"


def format_timestamp(seconds: float) -> str:
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds - int(seconds)) * 1000)
    return f"{hours:02}:{minutes:02}:{secs:02}.{millis:03}"


def whispers(
    audio: str,
    timestamps: str,
    model: str,
    device: Literal["cpu", "cuda", "auto"],
    compute_type: str,
    language: Optional[str],
    temperature: Union[float, List[float], Tuple[float, ...]],
    best_of: int,
    beam_size: int,
    patience: float,
    repetition_penalty: float,
    condition_on_previous_text: bool,
    no_speech_threshold: Optional[float],
    log_prob_threshold: Optional[float],
    compression_ratio_threshold: Optional[float],
    word_timestamps: bool,
    vad_filter: bool,
    rm_ts: bool,
    output_file: Optional[str],
):
    """
    Transcribe audio files with Whisper
    """

    print(f"Loading whisper '{model}'...")
    whisper_model = WhisperModel(
        model_size_or_path=model,
        device=device,
        compute_type=compute_type,
        # vad_method="pyannote_v3",
        # sentence=True,
        # standard_asia=True,
    )

    print("Extrapolating clips from timestamps...")
    with open(timestamps, "r", encoding="utf-8") as f:
        timestamp_file = json.load(f)

    print(f"Transcribing: {audio}")
    output = []
    for timestamp in timestamp_file:
        start_time = timestamp["start_time"] / 1000
        end_time = timestamp["end_time"] / 1000
        print(
            f"Line {timestamp['line_number']}: {format_timestamp(start_time)} -> {format_timestamp(end_time)}"
        )
        output.append(
            {
                "line_number": timestamp["line_number"],
                "start_time": timestamp["start_time"],
                "end_time": timestamp["end_time"],
            }
        )
        segments, _ = whisper_model.transcribe(
            audio,
            language=language,
            temperature=temperature,
            best_of=best_of,
            beam_size=beam_size,
            patience=patience,
            repetition_penalty=repetition_penalty,
            condition_on_previous_text=condition_on_previous_text,
            no_speech_threshold=no_speech_threshold,
            log_prob_threshold=log_prob_threshold,
            compression_ratio_threshold=compression_ratio_threshold,
            word_timestamps=word_timestamps,
            vad_filter=vad_filter,
            clip_timestamps=[start_time, end_time],
        )

        output[-1]["segments"] = []
        for segment in segments:
            print(
                f"[{format_timestamp(segment.start)} -> {format_timestamp(segment.end)}] {segment.text}"
            )
            output[-1]["segments"].append(segment.text)

    if rm_ts:
        os.remove(timestamps)

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(json.dumps(output, indent=4))


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio files with Whisper")
    parser.add_argument("audio", type=str, help="audio file to transcribe")
    parser.add_argument("timestamps", type=str, help="timestamps file")
    parser.add_argument(
        "--model",
        type=str,
        default="large-v2",
        help="model type (e.g. large-v2, large-v3, ...)",
    )
    parser.add_argument(
        "--device",
        type=str,
        default="cuda",
        help="device to use, cuda or cpu",
    )
    parser.add_argument(
        "--compute_type",
        type=str,
        default="float32",
        help="compute type (e.g. float32)",
    )
    parser.add_argument(
        "--language",
        type=str,
        default="ja",
        help="force language (e.g. 'ja' for Japanese, 'it' for Italian)",
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=0.4,
        help="temperature (e.g. 0.4)",
    )
    parser.add_argument(
        "--best_of",
        type=int,
        default=8,
        help="best_of (e.g. 8)",
    )
    parser.add_argument(
        "--beam_size",
        type=int,
        default=10,
        help="beam_size (e.g. 10)",
    )
    parser.add_argument(
        "--patience",
        type=float,
        default=2,
        help="patience (e.g. 2)",
    )
    parser.add_argument(
        "--repetition_penalty",
        type=float,
        default=1.4,
        help="repetition_penalty (e.g. 1.4)",
    )
    parser.add_argument(
        "--condition_on_previous_text",
        action="store_true",
        dest="condition_on_previous_text",
        help="condition_on_previous_text flag",
    )
    parser.add_argument(
        "--no_speech_threshold",
        type=float,
        default=0.275,
        help="no_speech_threshold (e.g. 0.275)",
    )
    parser.add_argument(
        "--log_prob_threshold",
        type=float,
        default=-1,
        help="log_prob_threshold (e.g. -1)",
    )
    parser.add_argument(
        "--compression_ratio_threshold",
        type=float,
        default=1.75,
        help="compression_ratio_threshold (e.g. 1.75)",
    )
    parser.add_argument(
        "--word_timestamps",
        action="store_true",
        dest="word_timestamps",
        help="word_timestamps flag",
    )
    parser.add_argument(
        "--vad_filter",
        action="store_true",
        dest="vad_filter",
        help="vad_filter flag",
    )
    parser.add_argument(
        "--no_rm_ts",
        action="store_false",
        dest="rm_ts",
        help="do not delete timestamps file after transcription",
    )
    parser.add_argument(
        "--output_file",
        type=str,
        default=None,
        help="file where write the output (e.g. 'path/to/output.txt')",
    )
    parser.add_argument("--version", action="version", version=__version__)

    args = parser.parse_args()
    whispers(
        audio=args.audio,
        timestamps=args.timestamps,
        model=args.model,
        device=args.device,
        compute_type=args.compute_type,
        language=args.language,
        temperature=args.temperature,
        best_of=args.best_of,
        beam_size=args.beam_size,
        patience=args.patience,
        repetition_penalty=args.repetition_penalty,
        condition_on_previous_text=args.condition_on_previous_text,
        no_speech_threshold=args.no_speech_threshold,
        log_prob_threshold=args.log_prob_threshold,
        compression_ratio_threshold=args.compression_ratio_threshold,
        word_timestamps=args.word_timestamps,
        vad_filter=args.vad_filter,
        rm_ts=args.rm_ts,
        output_file=args.output_file,
    )


if __name__ == "__main__":
    main()
