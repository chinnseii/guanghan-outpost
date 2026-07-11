# Sprint 07: Day 02 First Routine & Earth Report

《广寒前哨 Guanghan Outpost》

Version: 0.1  
Status: First playable pass

## Goal

Sprint 07 implements the first quiet daily loop after the player saves the last surviving plant in Sprint 06.

The goal is not to add a full survival or management system. The goal is to let the player understand that keeping Guanghan Outpost alive is now a daily responsibility:

- wake up in the old base
- receive a restrained morning status briefing
- check the central console
- inspect power, life support, water cycle and the last plant
- send the Day 02 Earth report
- receive ground acknowledgement
- end Day 02

## Included

- `Day02StartScene`
- `Day02EndScene`
- morning AI status briefing
- Day 02 HUD checklist
- power inspection
- life support inspection
- water cycle inspection
- last plant daily check
- Earth report terminal
- report preview and send flow
- Earth acknowledgement text
- Day 02 save fields

## Out Of Scope

- full time system
- full resource consumption
- full crop growth
- full communications system
- base building
- tech tree
- NPCs or residents
- automation
- mining
- random events
- failure/death systems
- formal Day 03 content

## Current Flow

```text
Day01EndScene
-> Day02StartScene
-> morning status briefing
-> OldBaseInteriorScene
-> central console daily check
-> daily inspections
-> OldGreenhouseScene
-> last plant and water-cycle checks
-> Earth report terminal
-> Earth acknowledgement
-> Day02EndScene
-> main menu / later content placeholder
```

## Save Data

The Sprint 07 pass extends `user://saves/sprint06_progress.json` with:

- `DayNumber`
- `Day02Started`
- `Day02ConsoleChecked`
- `Day02PowerChecked`
- `Day02LifeSupportChecked`
- `Day02WaterChecked`
- `Day02LastPlantChecked`
- `Day02InspectionsComplete`
- `Day02ReportPreviewed`
- `Day02ReportSent`
- `ArchiveEntry_Day02Report`
- `Day02Completed`

## Definition Of Done

- Day 02 starts after Day 01 rest.
- The player wakes in the habitation room.
- Morning AI briefing plays.
- Central console shows the D02 status summary.
- Daily checklist is visible.
- Power, life support, water cycle and last plant inspections can be completed.
- Earth report unlocks only after all four inspections.
- The player can preview and send the Day 02 report.
- Ground acknowledgement is shown after the report.
- The player can rest and end Day 02.
- Day 02 state saves.
- No full farming, resource, supply, base-building or Day 03 systems are added.
