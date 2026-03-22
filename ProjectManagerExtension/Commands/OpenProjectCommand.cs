// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace ProjectManagerExtension.Commands;

internal sealed partial class OpenProjectCommand : InvokableCommand
{
    private readonly string _projectPath;
    private readonly string _projectName;

    public OpenProjectCommand(string projectName, string projectPath)
    {
        _projectName = projectName;
        _projectPath = projectPath;
        Name = $"Open {projectName}";
    }

    public override CommandResult Invoke()
    {
        _= LaunchVsCodeAsync();
        return CommandResult.Dismiss();
    }

    private async Task LaunchVsCodeAsync()
    {
        await Task.Run(() =>
        {
            try
            {
                // Launch VS Code with the project path
                // For vscode-remote:// URIs, pass them as arguments to code.exe
                // code.exe --folder-uri "vscode-remote://..." will open a remote workspace
                var startInfo = new ProcessStartInfo
                {
                    FileName = "code",
                    UseShellExecute = true,
                };

                // If it's a vscode-remote URI, use --folder-uri flag
                if (_projectPath.StartsWith("vscode-remote://", StringComparison.OrdinalIgnoreCase))
                {
                    startInfo.Arguments = $"--folder-uri \"{_projectPath}\"";
                }
                else
                {
                    startInfo.Arguments = $"\"{_projectPath}\"";
                }

                Process.Start(startInfo);
            }
            catch (Exception)
            {
                // If VS Code fails to launch, silently fail
                // This could happen if 'code' is not in PATH or VS Code is not installed
            }
        });
    }
}
