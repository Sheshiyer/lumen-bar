#!/bin/zsh
# Render both films with HyperFrames, mux narration + music, and write a poster still.
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f build/onboarding/mix.wav && -f build/explainer/mix.wav ]] || python3 scripts/make_films.py
mkdir -p out build/video

(cd onboarding && npx --yes hyperframes@0.8.223 render --fps 30 -o ../build/video/onboarding.mp4)
(cd explainer && npx --yes hyperframes@0.8.223 render --fps 30 -o ../build/video/explainer.mp4)

# The onboarding voice ends at ~39.1s; trim its music-only tail to a 39.9s delivery.
ffmpeg -y -v error -i build/video/onboarding.mp4 -i build/onboarding/mix.wav \
  -map 0:v -map 1:a -t 39.9 -c:v copy -c:a aac -b:a 192k -movflags +faststart \
  out/lumenbar-onboarding.mp4
ffmpeg -y -v error -i build/video/explainer.mp4 -i build/explainer/mix.wav \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart \
  out/lumenbar-explainer.mp4
ffmpeg -y -v error -ss 67 -i out/lumenbar-explainer.mp4 -frames:v 1 out/poster-explainer.png

for f in out/lumenbar-onboarding.mp4 out/lumenbar-explainer.mp4; do
  echo "== $f"
  ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name,width,height \
    -of default=nw=1 "$f"
done
