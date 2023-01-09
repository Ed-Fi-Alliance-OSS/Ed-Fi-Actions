// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { existsSync } from 'fs';

import getCommandOptions from './cli.js';
import { initializeLogging, Logger } from './logger.js';
import scanDirectory from './scanFiles.js';

initializeLogging();
try {
  const { directory, recursive, configFile } = getCommandOptions();

  Logger.info('Arguments: ', directory, recursive, configFile);

  if (!existsSync(directory)) {
    throw Error(`Directory '${directory}' does not exist.`);
  }

  const found = scanDirectory(directory, recursive, config);

  if (found) {
    process.exit(1);
  }
  process.exit(0);
}
catch (e) {
  Logger.error(e);
  process.exit(2);
}
