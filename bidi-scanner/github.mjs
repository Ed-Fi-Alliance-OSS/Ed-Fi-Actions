// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';
import processFiles from './src/cli.mjs';
import { initializeLogging } from './src/githubLogger.mjs';

try {
  const directory = core.getInput('directory');
  const recursive = core.getInput('recursive');
  const configFile = core.getInput('config-file-path');

  if (!(process.env.GITHUB_ACTION)) {
    process.env.GITHUB_ACTION = true;
  }

  initializeLogging();

  const args = [
    '-d', directory, '-r', recursive, '-c', configFile,
  ];

  process.exit(processFiles(args));
} catch (error) {
  core.setFailed(error.message);
}
