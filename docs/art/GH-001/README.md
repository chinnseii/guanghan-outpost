# GH-001 Old Greenhouse Critical Target

Purpose:
This image defines the target look of the old greenhouse before the last plant is stabilized.

Use this as reference for:
- dark old greenhouse layout
- open hydroponic racks
- empty / dead plant trays
- broken or weak grow lights
- central plant chamber
- weak last surviving plant
- critical monitor status
- fragile green accent

Important visual rule:
The greenhouse itself is an indoor pressurized room.
Do NOT put every plant under glass domes.
Most hydroponic racks should be open trays.

Only the last surviving plant should be inside a small practical central plant chamber.
This chamber should look like an engineering life-support device:
- transparent front panel
- metal frame
- sensors
- small grow light
- water tube connection
- monitor

It should NOT look like a decorative glass display case.

Mood:
Fragile hope.
Quiet.
Critical but not horror.

Implementation notes:
- LastPlant state should be Critical.
- Plant should be darker, weaker, slightly drooping.
- Grow light should be weak or partially offline.
- Surrounding racks should remain dark and mostly dead.
- No reward effect.
- No magical glow.

Required reusable objects:
- HydroponicRackEmpty
- HydroponicRackDead
- CentralPlantChamber
- LastPlantCriticalSprite
- GrowLightOff
- WaterCyclePanelCritical
- PlantMonitorCritical

Acceptance target:
The player should immediately understand that most of the greenhouse failed, but one plant is still alive.