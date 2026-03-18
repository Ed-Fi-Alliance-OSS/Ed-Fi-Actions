// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { getInput, info, setFailed } from '@actions/core';
import { readConfig, scanDirectory } from '@edfi/bidi-scanner-lib';
import { initializeLogging } from './githubLogger.mjs';

try {
  // Overloads below are for localhost testing
  const directory = getInput('directory') || process.env.GH_DIRECTORY;
  const recursiveRaw = getInput('recursive') || process.env.GH_RECURSIVE;
  const configFile = getInput('config-file-path') || process.env.GH_CONFIG_FILE_PATH;

  // getInput returns a string; treat any value other than "false" as true (recursive is opt-out)
  const recursive = recursiveRaw !== 'false';

  const logger = initializeLogging();

  const ignore = readConfig(configFile, logger);

  info(`Excluding the following file types: ${JSON.stringify(ignore)}`);

  const found = scanDirectory(directory, recursive, ignore, logger);

  if (found) {
    setFailed('Bidirectional characters were encountered, please review log');
    process.exitCode = 1;
  }
} catch (error) {
  setFailed(error.message);
  process.exitCode = 3;
}
