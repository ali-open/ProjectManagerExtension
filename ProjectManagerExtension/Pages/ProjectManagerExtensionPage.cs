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

internal sealed partial class ProjectManagerExtensionPage : DynamicListPage
{
    private readonly ProjectsLoader _projectsLoader;

    public ProjectManagerExtensionPage(ProjectsLoader projectsLoader)
    {
        _projectsLoader = projectsLoader;
        Icon = IconHelpers.FromRelativePath("Assets\\StoreLogo.png");
        Title = "Project Manager";
        Name = "Open";
    }

    public override void UpdateSearchText(string oldSearch, string newSearch)
    {
        // Notify the UI that items have changed and need to be re-fetched
        RaiseItemsChanged();
    }

    public override IListItem[] GetItems()
    {
        var projects = _projectsLoader.GetProjects();
        var query = SearchText?.Trim() ?? string.Empty;

        // Filter projects based on segment search
        var filteredProjects = string.IsNullOrWhiteSpace(query)
            ? projects
            : projects.Where(p => SegmentSearchMatcher.Matches(p.Name, query)).ToList();

        // Convert to list items
        return filteredProjects
            .Select(p => new ListItem(new OpenProjectCommand(p.Name, p.RootPath))
            {
                Title = p.Name,
                Subtitle = p.RootPath,
            })
            .ToArray();
    }
}
