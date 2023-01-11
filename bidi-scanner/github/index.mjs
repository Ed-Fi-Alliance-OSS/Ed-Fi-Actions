// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';
import { readConfig, scanDirectory } from '@edfi/bidi-scanner-lib';
import { initializeLogging } from './githubLogger.mjs';

try {
  const directory = core.getInput('directory');
  const recursive = core.getInput('recursive');
  const configFile = core.getInput('config-file-path');

  if (!process.env.GITHUB_ACTION) {
    process.env.GITHUB_ACTION = true;
  }

  const logger = initializeLogging();

  const ignore = readConfig(configFile, logger);
  const found = scanDirectory(directory, recursive, ignore, logger);

  if (found) {
    core.ExitCode = 1;
    core.setFailed('Bidirectional characters were encountered, please review log');
  }
} catch (error) {
  core.setFailed(error.message);
}
