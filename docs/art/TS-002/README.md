# TS-002 Blue Home / 凝视地球

TS-002 is the first quiet event in the arrival prototype.

The player steps away from the transport ship, reaches a moon-surface overlook, stops moving, and looks back at Earth. The moment should feel small, silent and lonely rather than triumphant.

## Prototype Behavior

- Scene: `res://scenes/arrival/ArrivalLandingScene.tscn`
- Trigger area: a moon-surface region between the transport ship and the old base.
- Trigger condition: player stays still inside the region for at least 5 seconds.
- Event result: HUD weakens, camera briefly locks toward the Earth view, the AI speaks one line, and the event is marked as fired.
- Save behavior: once triggered and saved, the event should not repeat after loading.

## AI Line

```text
那里，是地球。
距离：384,400公里。
预计通信延迟：1.3秒。
```

## Art Reference

The folder contains the current TS-002 reference image generated during direction exploration. It is a mood target, not final production art.
