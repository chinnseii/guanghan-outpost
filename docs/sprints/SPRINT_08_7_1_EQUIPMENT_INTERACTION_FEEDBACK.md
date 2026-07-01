# Sprint 08.7.1 Addendum - Equipment Interaction Feedback

Status: Implemented / Awaiting owner review

## Goal

Make important equipment interactions feel procedural instead of instant checklist clicks.

## Implemented

- Training modules now lock movement briefly during important `E / Enter` interactions.
- Training devices show a small progress/status panel before the step completes.
- Training player visual enters a simple scan or repair pose during interaction.
- Training device target stays highlighted during the feedback sequence.
- Old Base / Week Routine interactions use a shared equipment feedback layer.
- Central console, power panel, power restart console, life support console, report terminal, plant monitor, and greenhouse devices now show short operation feedback.
- Report sending now shows uplink/transmission progress before report state is saved.
- Old Base player overlay shows scan/repair visual cues during equipment operation.

## State Update Rule

For patched actions, task state updates after the feedback sequence completes.

## No New Systems

This patch does not add minigames, inventory, full repair simulation, or Sprint 09 content.
