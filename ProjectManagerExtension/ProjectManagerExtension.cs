// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.CommandPalette.Extensions;
using ProjectManagerExtension.Services;

namespace ProjectManagerExtension;

[Guid("d08d2e87-5e1b-41d8-9505-abb3cbdf9287")]
public sealed partial class ProjectManagerExtension : IExtension, IDisposable
{
    private readonly ManualResetEvent _extensionDisposedEvent;
    private readonly ProjectsLoader _projectsLoader;
    private readonly ProjectManagerExtensionCommandsProvider _provider;

    public ProjectManagerExtension(ManualResetEvent extensionDisposedEvent)
    {
        this._extensionDisposedEvent = extensionDisposedEvent;
        this._projectsLoader = new ProjectsLoader();
        this._provider = new ProjectManagerExtensionCommandsProvider(_projectsLoader);
    }

    public object? GetProvider(ProviderType providerType)
    {
        return providerType switch
        {
            ProviderType.Commands => _provider,
            _ => null,
        };
    }

    public void Dispose()
    {
        _projectsLoader?.Dispose();
        _extensionDisposedEvent.Set();
    }
}
