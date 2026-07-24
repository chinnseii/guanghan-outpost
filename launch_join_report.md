# Launch join preview report

## Sources inspected

The requested logical source names map to the two files supplied earlier:

- `launch_part_01.mp4` → `C:\Users\csw83\OneDrive\桌面\art\航天视频\01\01.mp4`
- `launch_part_02.mp4` → `C:\Users\csw83\OneDrive\桌面\art\航天视频\02\0202.mp4`

Both source files were left unchanged.

| Property | Part 01 | Part 02 |
| --- | --- | --- |
| Video | H.264, 1920×1024, 24 fps, yuv420p | H.264, 1920×1024, 24 fps, yuv420p |
| Duration | 5.041667 s / 121 frames | 5.041667 s / 121 frames |
| Audio | AAC-LC, 48 kHz, stereo | AAC-LC, 48 kHz, stereo |

The last 1 second of part 01 and first 1 second of part 02 were exported as 24 PNG frames each under `seam_frames/`.

## Selected seam

- Part 01 tail trim: **0 frames**.
- Part 02 head trim: **9 frames** (0.375 s); the retained start is source frame 10.
- Best frame match: part 01 tail frame 24 ↔ part 02 head frame 10.
- Video dissolve: `xfade=transition=dissolve:duration=0.20:offset=4.841667`.
- Audio: source AAC was available, so it was retained and joined with `acrossfade=d=0.20`.

## Matching adjustments

- Output canvas: 1920×1080 at 24 fps. The 1920×1024 sources are vertically padded by 28 pixels above and below instead of being stretched.
- Part 02 position: shifted down **4 pixels**.
- Part 02 scale: **1.000** (no scaling applied).
- Part 02 brightness: **+0.011** in FFmpeg `eq` (a very small lift to match the selected seam frame).
- No blur, synthesized imagery, or text modification was used.

## Residual risk

Rocket body and tower geometry are closely aligned at the selected seam; their double-image risk is low. Smoke evolution differs between clips, so there is still a small risk of a brief texture discontinuity. The short 0.20-second dissolve limits this. Note that FFmpeg's `dissolve` transition intentionally produces a granular reveal during the transition; this is visible in the preview and should be assessed by a human before producing a final encode.

## Output

- `launch_joined_preview.mp4`
- H.264, 1920×1080, 24 fps, yuv420p; AAC-LC, 48 kHz stereo
- Duration: 9.541667 seconds
- Preview encode: CRF 28, `veryfast` preset

## FFmpeg command used

```powershell
ffmpeg -y -i "C:\Users\csw83\OneDrive\桌面\art\航天视频\01\01.mp4" -i "C:\Users\csw83\OneDrive\桌面\art\航天视频\02\0202.mp4" -filter_complex "[0:v]fps=24,scale=1920:1024:flags=lanczos,pad=1920:1080:0:28:color=black,settb=AVTB[v0];[1:v]trim=start_frame=9,setpts=PTS-STARTPTS,fps=24,scale=1920:1024:flags=lanczos,pad=1920:1080:0:28:color=black,eq=brightness=0.011,pad=1920:1088:0:4:color=black,crop=1920:1080:0:0,settb=AVTB[v1];[v0][v1]xfade=transition=dissolve:duration=0.20:offset=4.841667[v];[0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a0];[1:a]atrim=start=0.375,asetpts=PTS-STARTPTS,aformat=sample_rates=48000:channel_layouts=stereo[a1];[a0][a1]acrossfade=d=0.20:c1=tri:c2=tri[a]" -map "[v]" -map "[a]" -c:v libx264 -preset veryfast -crf 28 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "launch_joined_preview.mp4"
```
