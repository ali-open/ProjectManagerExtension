// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using ProjectManagerExtension.Models;

namespace ProjectManagerExtension.Services;

[JsonSourceGenerationOptions(PropertyNameCaseInsensitive = true)]
[JsonSerializable(typeof(List<ProjectItem>))]
internal partial class ProjectsLoaderJsonContext : JsonSerializerContext
{
}

public sealed partial class ProjectsLoader : IDisposable
{
    private readonly string _projectsFilePath;
    private readonly FileSystemWatcher? _fileWatcher;
    private List<ProjectItem> _cachedProjects = [];
    private readonly object _lock = new();

    public ProjectsLoader()
    {
        // Get the path to the VS Code Project Manager's projects.json file
        var appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        _projectsFilePath = Path.Combine(
            appDataPath,
            "Code",
            "User",
            "globalStorage",
            "alefragnani.project-manager",
            "projects.json");

        // Load initial projects
        LoadProjects();

        // Set up file watcher if the directory exists
        var directoryPath = Path.GetDirectoryName(_projectsFilePath);
        if (directoryPath != null && Directory.Exists(directoryPath))
        {
            try
            {
                _fileWatcher = new FileSystemWatcher(directoryPath)
                {
                    Filter = "projects.json",
                    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.CreationTime,
                    EnableRaisingEvents = true,
                };

                _fileWatcher.Changed += OnProjectsFileChanged;
                _fileWatcher.Created += OnProjectsFileChanged;
            }
            catch (Exception)
            {
                // If we can't create the file watcher, continue without it
                // The extension will still work with the initially loaded projects
                _fileWatcher = null;
            }
        }
    }

    private void OnProjectsFileChanged(object sender, FileSystemEventArgs e)
    {
        // Debounce multiple rapid file change events
        System.Threading.Thread.Sleep(100);
        LoadProjects();
    }

    private void LoadProjects()
    {
        lock (_lock)
        {
            try
            {
                if (!File.Exists(_projectsFilePath))
                {
                    _cachedProjects = [];
                    return;
                }

                var json = File.ReadAllText(_projectsFilePath);

                // Use source-generated JSON serialization for AOT compatibility
                var allProjects = JsonSerializer.Deserialize(
                    json,
                    ProjectsLoaderJsonContext.Default.ListProjectItem);

                // Filter to only enabled projects
                _cachedProjects = allProjects?
                    .Where(p => p.Enabled)
                    .ToList() ?? [];
            }
            catch (Exception)
            {
                // If we fail to load, keep the existing cached projects
                // This ensures the extension continues to work even if the file is temporarily corrupted
            }
        }
    }

    /// <summary>
    /// Gets the currently cached list of enabled projects.
    /// </summary>
    public IReadOnlyList<ProjectItem> GetProjects()
    {
        lock (_lock)
        {
            return _cachedProjects.ToList();
        }
    }

    public void Dispose()
    {
        if (_fileWatcher != null)
        {
            _fileWatcher.Changed -= OnProjectsFileChanged;
            _fileWatcher.Created -= OnProjectsFileChanged;
            _fileWatcher.EnableRaisingEvents = false;
            _fileWatcher.Dispose();
        }
    }
}
