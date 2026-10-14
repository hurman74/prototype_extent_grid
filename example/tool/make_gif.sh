#!/bin/sh
# Builds ../doc/demo.gif from the frames written by tool/render_screenshots.dart.
# Run from the example directory after `flutter test tool/render_screenshots.dart`.
set -e
frames=build/gif_frames
list=build/gif_frames.txt
: > "$list"
last=$(ls "$frames" | tail -1)
for f in "$frames"/*.png; do
  name=$(basename "$f")
  # Hold the first frame and the largest text size a little longer.
  case "$name" in 000.png|012.png) d=1.2 ;; *) d=0.12 ;; esac
  printf "file '%s'\nduration %s\n" "$(basename "$f")" "$d" >> "$list"
done
printf "file '%s'\n" "$last" >> "$list"
mv "$list" "$frames/list.txt"
ffmpeg -loglevel error -y -f concat -safe 0 -i "$frames/list.txt" \
  -vf "scale=400:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 ../doc/demo.gif
