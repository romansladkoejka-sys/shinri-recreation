@'
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
