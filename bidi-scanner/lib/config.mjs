// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { readFileSync, existsSync, statSync } from 'fs';
import { config } from './defaultConfig.mjs';

const loadJsonFile = (filePath, logger) => {
  if (!existsSync(filePath)) {
    throw Error(`Config file ${filePath} does not exist.`);
  }

  // This can occur when there is no config file, but GitHub Actions sends the
  // repository root directoy as the config file variable.
  if (statSync(filePath).isDirectory()) {
    return { exclude: [] };
  }

  logger.info(`Reading config file '${filePath}'`);
  const configContents = readFileSync(filePath, { encoding: 'utf8' });

  let optionalFile;
  try {
    optionalFile = JSON.parse(configContents);
  } catch {
    throw Error(`Config file ${filePath} contains invalid JSON.`);
  }

  if (!Array.isArray(optionalFile.exclude)) {
    throw Error(`Invalid config file ${filePath}: 'exclude' must be an array.`);
  }

  return optionalFile;
};

const readConfig = (optionalConfigFile, logger) => {
  if (optionalConfigFile) {
    const optionalConfig = loadJsonFile(optionalConfigFile, logger);
    return [...config.exclude, ...optionalConfig.exclude];
  }

  return config.exclude;
};

export { readConfig };
