# Intune Deployment Quick Reference

This is a condensed guide for IT administrators deploying the Project Manager Extension via Microsoft Intune Company Portal.

## Prerequisites

- Microsoft Intune admin access
- PowerShell 5.1+ and .NET 9 SDK (for building)
- Source code from this repository

---

## Deployment Strategy

### Bundle vs. Separate Packages

**Option 1: MSIX Bundle (Recommended)**
- ✅ Single file works on both x64 and ARM64 devices
- ✅ Simpler deployment - one app in Intune
- ✅ Windows automatically installs correct architecture
- ✅ Easier to maintain and update
- ⚠️ Slightly larger file size (contains both architectures)

**Option 2: Separate Architecture Packages**
- ✅ Smaller individual file sizes
- ✅ Can target specific device groups by architecture
- ⚠️ Requires two separate apps in Intune
- ⚠️ More complex to manage and update

**Recommendation:** Use the bundle approach unless you have specific requirements for separate packages.

---

## Build Process (One-Time Setup)

### 1. Create Signing Certificate

```powershell
cd C:\path\to\ProjectManagerExtension
.\Create-Certificate.ps1
```

**Output:**
- `Output\ProjectManagerExtension.pfx` - Keep secure (password: `YourPasswordHere`)
- `Output\ProjectManagerExtension.cer` - Upload to Intune

### 2. Build & Sign Package

**Option A: Build Multi-Architecture Bundle (Recommended)**

Single package works on both x64 and ARM64:

```powershell
# Build bundle with both architectures
.\Build-Bundle.ps1 -Configuration Release

# Sign bundle
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension.msixbundle" -Password 'YourPasswordHere'
```

**Output:** `Output\ProjectManagerExtension.msixbundle` (works on all architectures)

**Option B: Build Separate Packages**

If you prefer separate packages per architecture:

```powershell
# Build x64
.\Build-Installer.ps1 -Platform x64 -Configuration Release
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_x64.msix" -Password 'YourPasswordHere'

# Build ARM64
.\Build-Installer.ps1 -Platform ARM64 -Configuration Release
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_ARM64.msix" -Password 'YourPasswordHere'
```

**Output:** Two separate packages for each architecture

---

## Upload to Intune

### Step 1: Navigate to Apps

1. Open [Microsoft Intune admin center](https://endpoint.microsoft.com)
2. Go to **Apps** → **Windows** → **Add**
3. Select **Line-of-business app**

### Step 2: Upload Package

4. Click **Select app package file**
5. Browse and select:
   - **Bundle**: `ProjectManagerExtension.msixbundle` (recommended - works on all devices)
   - **OR Separate**: `ProjectManagerExtension_x64.msix` (x64 only)
6. Click **OK**

**Note:** If using a bundle, Windows automatically installs the correct architecture for each device.

### Step 3: Configure App Info

Fill in:
- **Name**: `Project Manager Extension for PowerToys`
- **Description**:
  ```
  Launch VS Code projects from PowerToys Command Palette with intelligent fuzzy search.

  Requires: PowerToys and VS Code with Project Manager extension installed.
  ```
- **Publisher**: `Your Organization Name`
- **App Version**: `0.0.1` (or current version)
- **Category**: Productivity
- **Show as featured app**: Optional
- **Information URL**: Leave blank or link to internal docs
- **Privacy URL**: Leave blank
- **Developer**: Your Name/Team

### Step 4: Upload Certificate ⚠️ CRITICAL

7. Scroll to **Certificate** section
8. Click **Select certificate file**
9. Upload: `Output\ProjectManagerExtension.cer`

**This makes the app "just work" for users - no manual certificate installation!**

### Step 5: Configure Scope Tags (Optional)

10. If using scope tags, add appropriate tags
11. Click **Next**

### Step 6: Assign to Groups

12. Under **Available for enrolled devices**, click **Add group**
13. Select user/device groups who should see the app in Company Portal
14. Click **Next**

**OR** use **Required** assignment to auto-install for specific groups

### Step 7: Review + Create

15. Review all settings
16. Click **Create**

---

## Post-Deployment

### Verification

After 5-10 minutes:
1. Open Company Portal on a test device
2. Search for "Project Manager"
3. Click **Install**
4. Verify it installs without errors

### Notify Users

Send communication with:
- App name and location (Company Portal)
- Prerequisites: PowerToys must be installed
- Usage: Press `Alt + Space`, type project name
- Support contact

---

## Updating to New Version

### When to Update

- Bug fixes
- New features
- Version increments in `Package.appxmanifest`

### Update Process

1. **Increment version** in `ProjectManagerExtension/Package.appxmanifest`:
   ```xml
   <Identity
     Name="ProjectManagerExtension"
     Version="0.0.2.0"  <!-- Increment this -->
     ...
   ```

2. **Rebuild and sign**:
   ```powershell
   .\Build-Installer.ps1 -Platform x64 -Configuration Release
   .\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_x64.msix"
   ```

3. **Update in Intune**:
   - Go to existing app in Intune
   - Click **Properties** → **App package file** → **Edit**
   - Upload new MSIX file
   - **No need to re-upload certificate** (unless it expired)
   - Save

4. **Intune auto-updates** all installations within 24 hours

---

## Troubleshooting

### Users Report "Can't Install" Error

**Cause**: Certificate not uploaded to Intune, or deployment not synced yet

**Fix**:
1. Verify `.cer` file is uploaded in app's Certificate section
2. Force device sync: Company Portal → Settings → Sync
3. Wait 5-10 minutes for policy to propagate

### App Not Appearing in Company Portal

**Cause**: User/device not in assigned group

**Fix**:
1. Check app assignments in Intune
2. Verify user is member of assigned group
3. Force sync on device

### PowerToys Command Palette Doesn't Show Projects

**Cause**: PowerToys not installed or not running

**Fix**:
1. Ensure PowerToys is installed
2. Enable Command Palette: PowerToys Settings → Command Palette → Toggle ON
3. Verify Command Palette hotkey works: `Alt + Space`
4. Check projects.json exists: `%AppData%\Code\User\globalStorage\alefragnani.project-manager\projects.json`

---

## Certificate Management

### Certificate Lifespan

Self-signed certificates created by `Create-Certificate.ps1`:
- **Valid for**: 10 years
- **Expires**: Check by opening `.cer` file

### When Certificate Expires

1. Generate new certificate: `.\Create-Certificate.ps1`
2. Update Package Publisher in `Package.appxmanifest` to match new certificate CN
3. Rebuild and sign with new certificate
4. Update app in Intune with new MSIX and new .cer file

---

## Cost Analysis

| Component | Cost |
|-----------|------|
| Self-signed certificate | **$0** |
| Intune licensing | **Included** (already have Intune) |
| Development tools | **$0** (free SDKs) |
| Distribution | **$0** (via Intune) |
| User installation friction | **$0** (automatic trust) |
| **Total** | **$0** 🎉 |

---

## Best Practices

✅ **Use Release builds** for production deployment<br>
✅ **Test on non-production group** first<br>
✅ **Document version numbers** in change log<br>
✅ **Keep PFX file secure** (password-protected, limited access)<br>
✅ **Backup certificate** to secure location<br>
✅ **Set app as "Available"** not "Required" initially<br>
✅ **Monitor installation metrics** in Intune reporting

---

## Quick Commands Reference

```powershell
# First time setup
.\Create-Certificate.ps1

# Multi-architecture bundle (recommended - works on all devices)
.\Build-Bundle.ps1 -Configuration Release
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension.msixbundle" -Password 'YourPassword'

# OR build separate packages per architecture
.\Build-Installer.ps1 -Platform x64 -Configuration Release
.\Sign-Package.ps1 -PackagePath ".\Output\ProjectManagerExtension_x64.msix" -Password 'YourPassword'

# Files to upload to Intune
# - Output\ProjectManagerExtension.msixbundle (bundle - recommended)
#   OR Output\ProjectManagerExtension_x64.msix (x64 only)
# - Output\ProjectManagerExtension.cer (first time only)

# Check current version
Get-AppxPackage | Where-Object { $_.Name -like "*ProjectManager*" }

# Force uninstall (if needed)
Get-AppxPackage *ProjectManager* | Remove-AppxPackage
```

---

## Support Escalation

| Issue | Contact |
|-------|---------|
| Build/signing errors | Development team |
| Intune deployment issues | IT admin / Intune administrator |
| User installation problems | IT helpdesk (check Company Portal sync) |
| App functionality bugs | Development team (file issue in repo) |
| PowerToys issues | PowerToys documentation / Microsoft |

---

## Additional Resources

- Full documentation: [INSTALLATION.md](./INSTALLATION.md)
- Feature overview: [README.md](./README.md)
- Intune app management: https://learn.microsoft.com/en-us/mem/intune/apps/
- PowerToys extensibility: https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview
