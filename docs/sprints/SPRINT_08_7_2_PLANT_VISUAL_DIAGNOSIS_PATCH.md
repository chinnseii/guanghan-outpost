# Sprint 08.7.2 - Plant Visual Diagnosis Patch

Status: Implemented / Awaiting owner review

## Goal

Make plant care feel like observation and diagnosis instead of text confirmation.

## Implemented Plant Conditions

- `critical` -> `assets/art/plants/diagnostics/last_plant_critical.png`
- `water_low` -> `assets/art/plants/diagnostics/last_plant_water_low.png`
- `light_low` -> `assets/art/plants/diagnostics/last_plant_light_low.png`
- `temp_high` -> `assets/art/plants/diagnostics/last_plant_temp_high.png`
- `temp_low` -> `assets/art/plants/diagnostics/last_plant_temp_low.png`
- `stable` -> `assets/art/plants/diagnostics/last_plant_stable.png`

## Diagnosis View

Old Greenhouse now has a reusable `PlantDiagnosisView` overlay:

- left side: close-up plant diagnostic image
- right side: sensor hints
- maintenance action buttons
- correct and incorrect feedback

## Maintenance Actions

- Water Low: `调整水循环`
- Light Low: `调整补光`
- Temperature High: `降低舱内温度`
- Temperature Low: `提升舱内温度`
- Critical tutorial state accepts both `调整水循环` and `调整补光`

Incorrect actions do not kill the plant in this demo. They show limited-effect feedback and allow retry.

## Integration

- Old Greenhouse monitor and diagnosis terminal can open the visual diagnosis view.
- Last Plant rescue can restore grow light and water cycle through diagnosis actions.
- Day 06 recovery can show the stable/improving diagnostic visual.

## Scope Guard

No crop system, random diseases, inventory, fertilizer, or Sprint 09 gameplay was added.
