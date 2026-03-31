# LootSuggestion

LootSuggestion is a WoW 3.3.5 addon for quick gear evaluation.

It scores items from stat weights, shows a tooltip score on hover, and can compare an item against what you currently have equipped. The current remake is built around class/spec presets instead of the older generic preset flow.

## Features

- Class/spec-based setup flow
- Tooltip item score and equipped comparison
- Weight and cap editors for the active build
- Priority wizard for manual tuning

## Current Model

The addon now uses:

- A visible class/spec selection in the main UI
- Hidden internal engine profiles for grouped logic such as caps and modifiers
- Source presets per class/spec to define the actual starting weights

In practice, users pick a class and spec, and LootSuggestion handles the internal profile selection automatically.

## Installation

Place the addon in your AddOns folder:

`Interface/AddOns/LootSuggestion`

Then reload the UI or restart the game.

## Usage

- Open the addon with `/ls`
- Pick your class and spec in the main window
- Hover items to see score and equipped comparison
- Use the editor buttons to adjust weights or caps if needed

Available slash commands:

- `/ls`
- `/ls setup`
- `/ls edit`
- `/ls capedit`
- `/ls weights`
- `/ls caps`

## Notes

- Saved variables are stored per character in `LootSuggestion`
- Weapon comparison now handles shield builds, dual-wield setups, and 2H replacements more explicitly than before
- Preset values are intended as starting points and can be tuned further in-game