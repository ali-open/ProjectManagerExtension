# Project Manager Extension - Installation Guide

This guide explains how to build and deploy the Project Manager extension for PowerToys Command Palette through the Intune Company Store.

## Overview

This extension is **designed for Intune deployment**. When deployed via Intune, the certificate trust is handled automatically - users simply install from the Company Portal with zero friction.

---

## For IT Admins (Building and Publishing to Intune)

### Prerequisites
- Visual Studio 2022 or .NET 9 SDK
- Windows 10/11 SDK
- PowerShell 5.1 or later
- Access to Microsoft Intune admin center

### Step 1: Create a Signing Certificate (First Time Only)

Run this once to create a self-signed certificate:

```powershell
.\Create-Certificate.ps1
```

This creates:
- `Output\ProjectManagerExtension.pfx` - Used for signing (keep secure)
- `Output\ProjectManagerExtension.cer` - Upload to Intune (Intune handles trust automatically)

**Note**: The default password is `YourPasswordHere` - keep the PFX file secure!

### Step 2: Build the MSIX Package

**Option A: Multi-Architecture Bundle (Recommended)**

Build a single package that works on both x64 and ARM64:

```powershell
.\Build-Bundle.ps1 -Configuration Release
```

Output: `Output\ProjectManagerExtension.msixbundle`

**Option B: Architecture-Specific Packages**

Build for x64 (most common):

```powershell
.\Build-Installer.ps1 -Platform x64 -Configuration Release
```

Or for ARM64:

```powershell
.\Build-Installer.ps1 -Platform ARM64 -Configuration Release
```

Output: `Output\ProjectManagerExtension_x64.msix` or `Output\ProjectManagerExtension_ARM64.msix`

### Step 3: Sign the Package

```powershell
# For bundle
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension.msixbundle" -Password 'YourPassword'

# OR for individual packages
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_x64.msix" -Password 'YourPassword'
```

### Step 4: Upload to Intune

1. Sign in to [Microsoft Intune admin center](https://endpoint.microsoft.com)
2. Navigate to **Apps** → **Windows** → **Add**
3. Select **Windows app (Win32)** or **Line-of-business app**
4. Click **Select app package file** and upload:
   - `ProjectManagerExtension.msixbundle` (recommended - works on all devices)
   - OR `ProjectManagerExtension_x64.msix` (x64 only)

**Note:** If using a bundle, Windows automatically selects and installs the correct architecture for each device.

#### Configure App Information:
- **Name**: Project Manager Extension for PowerToys
- **Description**: Launch VS Code projects directly from PowerToys Command Palette with segment-based search
- **Publisher**: Your Organization Name
- **Category**: Productivity (optional)

#### Configure Certificate (Critical Step):
5. In the **App information** section, find **Certificate**
6. Upload `Output\ProjectManagerExtension.cer`
7. Intune will automatically install this certificate to the Trusted People store during deployment

#### Assign to Users/Groups:
8. Go to **Assignments** tab
9. Add groups under **Available for enrolled devices** (for Company Portal) or **Required** (auto-install)
10. Click **Review + Save**

### Step 5: Notify Users

Once published, users will see "Project Manager Extension for PowerToys" in their Company Portal app or web portal.

---

## For End Users (Installing from Company Portal)

### Prerequisites
- PowerToys must be installed ([download here](https://github.com/microsoft/PowerToys/releases))
- VS Code with [Project Manager extension](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager) (to manage your project list)

### Installation Steps

**This is incredibly simple when deployed via Intune!**

1. Open **Company Portal** app (or visit the web portal)
2. Search for **"Project Manager Extension"**
3. Click **Install**
4. Wait for installation to complete (usually 10-30 seconds)

That's it! 🎉 **No certificate installation, no admin rights needed, no manual configuration.**

### First Use

Once installed:
1. Make sure you have projects saved in VS Code Project Manager extension
2. Open PowerToys Command Palette (default: `Alt + Space`)
3. Start typing a project name
4. Your projects appear automatically!
5. Press Enter to launch the project in VS Code

---

## Using the Extension

### Search Examples

For a project named `platform-core-testy-mctest`:
- Simple: `testy` → ✅ matches
- Segment-based: `p-c-t-m` → ✅ matches (first letter of each segment)
- Partial: `test-m` → ✅ matches
- Anywhere: `mcte` → ✅ matches

The extension supports flexible fuzzy searching designed for hyphenated project names!

---

## Troubleshooting

### Projects Don't Appear
1. Make sure PowerToys is running (check system tray)
2. Verify PowerToys Command Palette is enabled (PowerToys Settings → Command Palette → toggle ON)
3. Check that projects.json exists at:<br>
   `%AppData%\Code\User\globalStorage\alefragnani.project-manager\projects.json`
4. In VS Code, add some projects using the Project Manager extension
5. Restart PowerToys (right-click tray icon → Quit, then relaunch)

### Extension Not in Company Portal
→ Contact your IT admin - the app may not be assigned to your group yet

### Installation Failed
→ Ensure PowerToys is closed during installation (Intune usually handles this automatically)

### Want to Uninstall
```powershell
Remove-AppxPackage -Package "ProjectManagerExtension_0.0.1.0_x64__8wekyb3d8bbwe"
```

Or: Settings → Apps → Installed apps → Search "Project Manager" → Uninstall

---

## Updating to a New Version

### For IT Admins
1. Build the new version (increment version number in Package.appxmanifest first)
2. Sign the new MSIX package
3. In Intune admin center, go to the existing app
4. Click **Properties** → **App package file** → **Edit**
5. Upload the new MSIX file
6. Save - Intune will automatically update all installed instances

**Recommended**: Configure the app assignment with **Update automatically** enabled

### For End Users
Updates happen automatically via Intune! You may see a notification that the app is updating. No action required.

---

## Alternative Deployment: Manual Installation (Without Intune)

If you need to install without Intune (e.g., testing on a personal machine):

### Prerequisites
- Have both files: `.msix` package and `.cer` certificate

### Steps
1. **Install Certificate** (Admin PowerShell):
   ```powershell
   Import-Certificate -FilePath ".\Output\ProjectManagerExtension.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPeople
   ```

2. **Install Package**:
   ```powershell
   Add-AppxPackage -Path ".\ProjectManagerExtension_x64.msix"
   ```

This method requires local admin rights and manual certificate installation.

---

## Data Source

The extension reads VS Code Project Manager's data file:
```
%AppData%\Code\User\globalStorage\alefragnani.project-manager\projects.json
```

### File Watcher
The extension automatically detects changes to projects.json:
- ✅ Add a project in VS Code → immediately appears in PowerToys
- ✅ Remove a project → immediately disappears
- ✅ No restart required

### Remote Projects
The extension fully supports VS Code Remote Development projects:
- ✅ WSL projects (`vscode-remote://wsl+Ubuntu/...`)
- ✅ SSH projects (`vscode-remote://ssh-remote+...`)
- ✅ Dev Container projects (`vscode-remote://dev-container+...`)

---

## Requirements Summary

- **PowerToys** (free) - [Download](https://github.com/microsoft/PowerToys/releases)
- **VS Code** (free) - [Download](https://code.visualstudio.com/)
- **VS Code Project Manager extension** (free) - [Install](https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager)
- **Company Portal** (if deploying via Intune) - Pre-installed on managed devices

**Total cost: $0** 🎉

---

## Support

For issues or feature requests:
- Check troubleshooting section above
- Contact your IT administrator for Intune deployment issues
- File an issue in the project repository for bugs or enhancements
