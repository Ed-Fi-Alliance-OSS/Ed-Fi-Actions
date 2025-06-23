# Issue Management

This directory contains the automated issue management system for the Ed-Fi Actions repository.

## Overview

GitHub Issues in this repository are for use by the Ed-Fi engineering team only. Community members seeking technical support should use the [Ed-Fi Community Hub](https://community.ed-fi.org) instead.

## Components

### 1. Issue Management Workflow (`.github/workflows/issue-management.yml`)

Automatically manages issues opened by community members:

- **Triggers**: When a new issue is opened
- **Logic**: 
  - Checks if the issue author has repository access (triage, write, maintain, admin)
  - If no repository access or only read access, closes the issue with a helpful message directing them to the Community Hub
  - If has triage or above access, the issue remains open for normal processing

### 2. Issue Templates (`.github/ISSUE_TEMPLATE/`)

Provides structured templates for different types of issues:

- **`config.yml`**: Disables blank issues and provides direct links to community resources
- **`community-support.yml`**: Template that redirects community members to the proper support channels
- **`engineering-issue.yml`**: Template for engineering team members to create internal issues

## Features

- **Automatic closure**: Issues from users without triage or above repository access are automatically closed
- **Helpful messaging**: Closed issues include clear instructions on where to get support
- **Repository access detection**: Uses GitHub repository permissions to identify authorized users
- **Proactive guidance**: Issue templates guide users to appropriate channels before issue creation

## How It Works

1. **Prevention**: Issue templates and configuration guide users to the Community Hub
2. **Detection**: When an issue is opened, the workflow checks repository access permissions
3. **Action**: Issues from users without triage or above repository access are closed with a helpful message
4. **Guidance**: Clear instructions direct users to the Ed-Fi Community Hub

## Configuration

The workflow is configured to check repository access permissions for the current repository. Users with triage or above repository access (triage, write, maintain, admin) are allowed to create issues. Users with only read access or no access will have their issues automatically closed. This configuration can be found in the workflow file.

## Support Channels

- **Repository Collaborators with Triage+ Access**: Use GitHub Issues in this repository
- **Community Members**: Use the [Ed-Fi Community Hub](https://community.ed-fi.org)
- **Documentation**: [Ed-Fi Technical Documentation](https://docs.ed-fi.org)