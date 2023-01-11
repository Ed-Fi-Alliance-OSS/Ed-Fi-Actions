// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { readFileSync, existsSync } from 'fs';

const getDefaultConfigPath = () => {
  const filename = fileURLToPath(import.meta.url);
  const thisDirectory = dirname(filename);
  return join(thisDirectory, '..', 'config.json');
};

const loadJsonFile = (filePath, logger) => {
  if (!existsSync(filePath)) {
    throw Error(`Config file ${filePath} does not exist.`);
  }

  logger.info(`Reading config file '${filePath}'`);
  const configContents = readFileSync(filePath, { encoding: 'utf8' });
  const config = JSON.parse(configContents);

  if (!('exclude' in config)) {
    throw Error(`Invalid config file ${filePath}.`);
  }

  return config;
};

const readConfig = (optionalConfigFile, logger) => {
  const config = loadJsonFile(getDefaultConfigPath(), logger);

  if (optionalConfigFile) {
    const optionalConfig = loadJsonFile(optionalConfigFile, logger);
    return [...config.exclude, ...optionalConfig.exclude];
  }

  return config.exclude;
};

export { readConfig };
