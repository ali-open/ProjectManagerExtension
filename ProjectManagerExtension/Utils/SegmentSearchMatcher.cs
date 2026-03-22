// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Linq;

namespace ProjectManagerExtension.Utils;

public static class SegmentSearchMatcher
{
    /// <summary>
    /// Matches search query against project name using segment-based fuzzy matching.
    /// Splits both query and project name by '-' and matches segments in order.
    /// Search segments can match anywhere within project name segments.
    /// </summary>
    /// <param name="projectName">The project name to search in.</param>
    /// <param name="query">The search query.</param>
    /// <returns>True if the query matches the project name.</returns>
    public static bool Matches(string projectName, string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return true;
        }

        if (string.IsNullOrWhiteSpace(projectName))
        {
            return false;
        }

        // Convert to lowercase for case-insensitive matching
        var lowerProjectName = projectName.ToLowerInvariant();
        var lowerQuery = query.ToLowerInvariant();

        // Split by dash to get segments
        var querySegments = lowerQuery.Split('-', StringSplitOptions.RemoveEmptyEntries);
        var projectSegments = lowerProjectName.Split('-', StringSplitOptions.RemoveEmptyEntries);

        if (querySegments.Length == 0)
        {
            return true;
        }

        // Track current position in project segments
        int projectSegmentIndex = 0;

        // Try to match each query segment in order
        foreach (var querySegment in querySegments)
        {
            bool foundMatch = false;

            // Search from current position forward
            while (projectSegmentIndex < projectSegments.Length)
            {
                if (projectSegments[projectSegmentIndex].Contains(querySegment))
                {
                    foundMatch = true;
                    projectSegmentIndex++; // Move to next segment for next search
                    break;
                }

                projectSegmentIndex++;
            }

            // If we couldn't find this query segment, no match
            if (!foundMatch)
            {
                return false;
            }
        }

        return true;
    }
}
