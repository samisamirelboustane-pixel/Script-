# Brainrot Spawner — All-In-One Script

A single Roblox Script that runs both server-side spawning logic and a client-side menu (via RunContext self-clone).

## Features

- Server-authoritative spawning (everyone sees spawns)
- Auto-discovers REAL Brainrot models from CollectionService tags or named folders
- Toggleable client menu (press **RightControl** to show/hide)
- Spawn random or by rarity
- Auto-spawn with configurable interval
- Weighted rarity system with mutations (Rainbow, Diamond, Gold)
- Conveyor belt system that moves spawned models
- Draggable menu window

## Setup

1. Place this as a **Script** in `ServerScriptService` (RunContext = Legacy, the default)
2. Press Play — the menu appears automatically
3. Toggle with **RightControl**

## File

- `BrainrotSpawner.lua` — the complete all-in-one script
