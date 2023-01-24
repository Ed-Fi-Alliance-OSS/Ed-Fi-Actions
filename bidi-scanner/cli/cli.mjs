// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { existsSync } from 'fs';

import yargs from 'yargs';

import { scanDirectory, readConfig } from '@edfi/bidi-scanner-lib';

const getCommandOptions = (args) => yargs(args)
  .scriptName('$0')
  .options({
    d: {
      type: 'string',
      demandOption: true,
      alias: 'directory',
      description: 'directory to scan',
    },
    r: {
      type: 'boolean',
      demandOption: false,
      alias: 'recursive',
      describe: 'recursive directory search',
      default: true,
    },
    c: {
      type: 'string',
      demandOption: false,
      alias: 'config-file',
      describe: 'config file path',
    },
  })
  .epilog('Scans a directory for bidirectional Trojan Source attacks.')
  .parseSync();

const processFiles = (logger, args) => {
  try {
    const { directory, recursive, configFile } = getCommandOptions(args);

    logger.info('Arguments: ', directory, recursive, configFile);

    if (!existsSync(directory)) {
      throw Error(`Directory '${directory}' does not exist.`);
    }

    const ignore = readConfig(configFile, logger);

    logger.info(`Excluding the following file types: ${JSON.stringify(ignore)}`);

    const found = scanDirectory(directory, recursive, ignore, logger);

    if (found) {
      return 1;
    }
    return 0;
  } catch (e) {
    logger.error(e);
    return 2;
  }
};

export { processFiles };
