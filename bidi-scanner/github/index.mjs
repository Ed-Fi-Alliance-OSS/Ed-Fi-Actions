// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';
import { readConfig, scanDirectory } from '@edfi/bidi-scanner-lib';
import { initializeLogging } from './githubLogger.mjs';

try {
  // Overloads below are for localhost testing
  const directory = core.getInput('directory') || process.env.GH_DIRECTORY;
  const recursive = core.getInput('recursive') || process.env.GH_RECURSIVE;
  const configFile = core.getInput('config-file-path') || process.env.GH_CONFIG_FILE_PATH;

  const logger = initializeLogging();

  const ignore = readConfig(configFile, logger);

  core.info(`Excluding the following file types: ${JSON.stringify(ignore)}`);

  const found = scanDirectory(directory, recursive, ignore, logger);

  if (found) {
    core.ExitCode = found;
    core.setFailed('Bidirectional characters were encountered, please review log');

    // The above should be failing the GitHub job, but its not working out.
    process.ExitCode = found;
  }
} catch (error) {
  core.setFailed(error.message);
  process.ExitCode = 3;
}
