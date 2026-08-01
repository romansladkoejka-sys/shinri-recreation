# Shinri Recreation

Shinri Recreation is an early-stage open-source Garry's Mod gamemode project written in Lua.

The project explores the development of a multiplayer social-deduction and courtroom-style roleplay experience, with custom interfaces, character systems, communication tools, and gameplay infrastructure.

## Project Status

The project is currently in active early development.

The public repository contains the initial playable framework and interface systems. Additional gameplay stages, multiplayer state management, investigation mechanics, trial systems, documentation, and development tools are planned for future versions.

## Current Features

- Garry's Mod gamemode initialization
- Client and server Lua structure
- Character selection and character handling
- Custom player chat interface
- Custom escape menu
- Inventory interface prototype
- Shared UI colors, fonts, and materials
- Initial multiplayer networking logic

## Repository Structure

```text
cl_init.lua          Client initialization
init.lua             Server initialization
shared.lua           Shared gamemode configuration
cl_characters.lua    Client-side character system
sv_characters.lua    Server-side character system
cl_chat.lua          Custom chat interface
cl_escape_menu.lua   Custom escape menu
ui/                  Reusable interface components
```

## Goals

The long-term goal is to build a documented and maintainable Garry's Mod framework for social-deduction and courtroom-oriented multiplayer gamemodes.

Planned areas include:

- structured game-session states;
- investigation and evidence systems;
- debate, voting, and verdict stages;
- reconnect-safe player state;
- spectator support;
- reusable UI components;
- automated QA and development tools;
- contributor documentation.

## Installation

This repository is intended for development and testing.

1. Install a Garry's Mod dedicated server or local development server.
2. Place the gamemode files in the appropriate `garrysmod/gamemodes/` directory.
3. Ensure the gamemode has its own folder and standard Garry's Mod gamemode structure.
4. Start the server with the gamemode selected.

The installation process will be documented in more detail as the project structure is stabilized.

## Contributing

The project is currently maintained independently, but constructive issues, technical feedback, documentation improvements, and code contributions are welcome.

Before contributing, please avoid uploading copyrighted game assets, Workshop content, music, maps, models, textures, or other files that you do not have permission to redistribute.

## Legal Notice

This repository contains original development work for Garry's Mod.

It does not include proprietary maps, music, models, textures, or other copyrighted assets from third-party games or Workshop packages.

Garry's Mod is developed by Facepunch Studios. This project is not affiliated with or endorsed by Facepunch Studios.

## License

The original source code in this repository is available under the MIT License. See [LICENSE](LICENSE).
