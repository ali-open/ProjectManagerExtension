# Project Manager Extension for PowerToys Command Palette

Launch your VS Code projects directly from PowerToys Command Palette with intelligent segment-based fuzzy search!

## Overview

This PowerToys extension integrates with the [VS Code Project Manager extension](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager), exposing all your saved projects to PowerToys Command Palette for instant access.

### Features

✅ **Instant VS Code Project Launching** - Open any project with just a few keystrokes<br>
✅ **Segment-Based Fuzzy Search** - Optimized for hyphenated project names<br>
✅ **Auto-Reload** - FileSystemWatcher detects project.json changes automatically<br>
✅ **Remote Development Support** - Full support for WSL, SSH, and Dev Container projects<br>
✅ **Zero Configuration** - Automatically reads from VS Code Project Manager's data file<br>
✅ **Intune Ready** - Designed for enterprise deployment via Company Portal

---

## Quick Start

### For End Users (Intune Deployment)

1. Install from **Company Portal**
2. Open PowerToys Command Palette (`Alt + Space`)
3. Start typing a project name
4. Press Enter to launch in VS Code

That's it! No configuration needed.

### For IT Admins

See [INSTALLATION.md](./INSTALLATION.md) for complete build and deployment instructions.

**Quick Build:**
```powershell
.\Create-Certificate.ps1              # One-time
.\Build-Installer.ps1 -Platform x64   # Build
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_x64.msix"  # Sign
```

Upload to Intune and you're done!

---

## Intelligent Search

### Segment-Based Matching

Project name: `platform-core-testy-mctest`

**All of these work:**
- `p-c-t-m` → ✅ First letter of each segment
- `testy` → ✅ Full segment match
- `test-m` → ✅ Partial segments
- `p-c-mctest` → ✅ Mixed full and partial
- `mcte` → ✅ Substring anywhere

The search algorithm splits project names on hyphens and matches segments in order, allowing both full and partial matches.

---

## Technical Details

### Data Source

Reads project list from VS Code Project Manager's storage:
```
%AppData%\Code\User\globalStorage\alefragnani.project-manager\projects.json
```

Sample data structure available in [`Sample/projects.json`](./Sample/projects.json)

### Architecture

- **Models**: `ProjectItem` - JSON deserialization model for VS Code Project Manager format
- **Services**: `ProjectsLoader` - Singleton service with FileSystemWatcher, caching, and auto-reload
- **Utilities**: `SegmentSearchMatcher` - Custom fuzzy search algorithm
- **Commands**: `OpenProjectCommand` - InvokableCommand that launches VS Code with proper URI handling
- **Provider**: `ProjectManagerExtensionCommandsProvider` - Implements IFallbackHandler for advanced search

### File Watching

Built-in FileSystemWatcher monitors projects.json:
- **Debounced**: 100ms delay prevents multiple rapid reloads
- **Automatic**: Changes detected instantly without restart
- **Cleanup**: Proper IDisposable implementation prevents resource leaks

### Remote Development

Detects `vscode-remote://` URIs and uses proper launch flags:
```bash
# Local projects
code "C:\path\to\project"

# Remote projects (WSL, SSH, containers)
code --folder-uri "vscode-remote://wsl+Ubuntu/home/user/project"
```

---

## Requirements

- **PowerToys** (free) - [Download](https://github.com/microsoft/PowerToys/releases)
- **VS Code** (free) - [Download](https://code.visualstudio.com/)
- **VS Code Project Manager** (free) - [Install](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager)

**No paid software required!**

---

## Development

### Tech Stack

- **.NET 9** with Windows App SDK
- **PowerToys Command Palette SDK**
- **System.Text.Json** with source generation (AOT-compatible)
- **MSIX Packaging** for enterprise deployment

### Build Prerequisites

- Visual Studio 2022 or .NET 9 SDK
- Windows 10/11 SDK (10.0.26100.0 or later)
- PowerShell 5.1+

### Local Development Build

```powershell
# Restore dependencies
dotnet restore

# Build
dotnet build -c Debug

# Run (PowerToys must be installed)
# The extension will appear in PowerToys Command Palette automatically
```

---

## Deployment Options

### 1. Intune Company Portal (Recommended)
- ✅ **Zero user friction** - Certificate trust handled automatically
- ✅ **Centralized management** - Track deployments, force updates
- ✅ **Self-service** - Users install when ready
- ✅ **Free** - Uses existing Intune infrastructure

See [INSTALLATION.md](./INSTALLATION.md) for complete Intune deployment guide.

### 2. Manual Distribution
- Requires distributing both `.msix` and `.cer` files
- Users must manually install certificate (admin rights required)
- See "Alternative Deployment" section in [INSTALLATION.md](./INSTALLATION.md)

---

## License

See [LICENSE.txt](./LICENSE.txt)

---

## References

- [PowerToys Command Palette Extensibility](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview)
- [VS Code Project Manager Extension](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager)
- [MSIX Packaging Documentation](https://learn.microsoft.com/en-us/windows/msix/)
- [Intune App Deployment](https://learn.microsoft.com/en-us/mem/intune/apps/apps-add)