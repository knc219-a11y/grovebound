#!/usr/bin/env python3
"""Render a Godot review scene and produce a still or GIF + MP4. Stdlib only."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ERROR_MARKERS = ("SCRIPT ERROR:", "Parse Error:", "ERROR:")


def run(command, *, cwd, check_godot=False, timeout=180):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=timeout)
    log = result.stdout + result.stderr
    if result.returncode or (check_godot and any(s in log for s in ERROR_MARKERS)):
        raise RuntimeError(f"Failed: {command[0]}\n{log[-10000:]}")
    return log


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--godot", default="godot")
    p.add_argument("--scene", required=True, help="res://animation/review.tscn")
    p.add_argument("--out", required=True, help="Output stem, relative to project")
    p.add_argument("--mode", choices=["clip", "still"], default="clip")
    p.add_argument("--seconds", type=float, default=6.0)
    p.add_argument("--fps", type=int, default=30)
    p.add_argument("--gif-fps", type=int, default=12)
    p.add_argument("--width", type=int, default=768)
    p.add_argument("--skip-import", action="store_true")
    args = p.parse_args()
    if not (0 < args.seconds <= 30 and 1 <= args.fps <= 60 and 1 <= args.gif_fps <= 30
            and 320 <= args.width <= 1920 and args.width % 2 == 0):
        p.error("Use 0 < seconds <= 30, fps <= 60, GIF fps <= 30, even width 320..1920")
    project = Path(__file__).resolve().parent.parent
    if not args.scene.startswith("res://") or not (project / args.scene[6:]).is_file():
        p.error("Scene must be an existing res:// path in this project")
    godot = shutil.which(args.godot)
    if not godot:
        candidate = Path(args.godot).expanduser().resolve()
        if candidate.is_file(): godot = str(candidate)
    ffmpeg = shutil.which("ffmpeg")
    if not godot or not ffmpeg:
        p.error("Godot and FFmpeg are required; pass --godot PATH and put FFmpeg on PATH")
    if sys.platform.startswith("linux") and not (os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")):
        p.error("Recording needs a graphics display (local desktop or Xvfb); headless mode cannot render images")
    output = Path(args.out)
    if not output.is_absolute(): output = project / output
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="grove-preview-") as temp:
        movie = Path(temp) / "capture.avi"
        if not args.skip_import:
            run([godot, "--headless", "--path", str(project), "--editor", "--import", "--quit"],
                cwd=project, check_godot=True)
        frames = max(3, round(args.seconds * args.fps)) if args.mode == "clip" else 3
        command = [godot, "--path", str(project), "--audio-driver", "Dummy",
                   "--write-movie", str(movie), "--fixed-fps", str(args.fps),
                   "--quit-after", str(frames), args.scene]
        if sys.platform.startswith("linux") and os.getenv("DISPLAY"):
            command[1:1] = ["--display-driver", "x11"]
        run(command, cwd=project, check_godot=True)
        if not movie.is_file() or movie.stat().st_size == 0:
            raise RuntimeError("Godot produced no movie")
        base = [ffmpeg, "-y", "-loglevel", "error", "-i", str(movie)]
        outputs = []
        if args.mode == "still":
            image = output.with_suffix(".png")
            run(base + ["-frames:v", "1", str(image)], cwd=project)
            outputs.append(image)
        else:
            video = output.with_suffix(".mp4")
            run(base + ["-an", "-vf", f"scale={args.width}:-2", "-c:v", "libx264", "-crf", "23",
                        "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(video)], cwd=project)
            gif = output.with_suffix(".gif")
            filters = (f"[0:v]fps={args.gif_fps},scale={args.width}:-2:flags=lanczos,split[a][b];"
                       "[a]palettegen=max_colors=80:stats_mode=diff[p];"
                       "[b][p]paletteuse=dither=none:diff_mode=rectangle")
            run(base + ["-filter_complex", filters, str(gif)], cwd=project)
            run([ffmpeg, "-v", "error", "-i", str(video), "-f", "null", "-"], cwd=project)
            outputs.extend([gif, video])
        for item in outputs:
            print(f"OK {item} ({item.stat().st_size:,} bytes)")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
