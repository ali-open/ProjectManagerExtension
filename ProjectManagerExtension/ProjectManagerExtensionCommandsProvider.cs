// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System.Linq;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;
using ProjectManagerExtension.Commands;
using ProjectManagerExtension.Services;
using ProjectManagerExtension.Utils;

namespace ProjectManagerExtension;

public partial class ProjectManagerExtensionCommandsProvider : CommandProvider, IFallbackHandler
{
    private readonly ProjectsLoader _projectsLoader;

    public ProjectManagerExtensionCommandsProvider(ProjectsLoader projectsLoader)
    {
        _projectsLoader = projectsLoader;
        DisplayName = "Project Manager";
        Icon = IconHelpers.FromRelativePath("Assets\\StoreLogo.png");
    }

    public override ICommandItem[] TopLevelCommands()
    {
        // Return projects directly as top-level commands
        // This makes them immediately searchable without selecting an intermediate item
        var projects = _projectsLoader.GetProjects();

        return projects
            .Select(p => new ListItem(new OpenProjectCommand(p.Name, p.RootPath))
            {
                Title = p.Name,
                Subtitle = p.RootPath,
            })
            .ToArray<ICommandItem>();
    }

    // IFallbackHandler implementation for custom segment-based search
    public void UpdateQuery(string query)
    {
        // This method is called when the search query changes
        // We don't need to do anything here as we calculate results on-demand in FallbackCommands
    }

    public ICommandItem[] FallbackCommands(string searchQuery)
    {
        if (string.IsNullOrWhiteSpace(searchQuery))
        {
            return [];
        }

        var projects = _projectsLoader.GetProjects();

        // Use segment-based search to match projects
        return projects
            .Where(p => SegmentSearchMatcher.Matches(p.Name, searchQuery))
            .Select(p => new ListItem(new OpenProjectCommand(p.Name, p.RootPath))
            {
                Title = p.Name,
                Subtitle = p.RootPath,
            })
            .ToArray<ICommandItem>();
    }
}
