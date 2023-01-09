// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

const getCommandOptions = () => yargs(hideBin(process.argv))
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
      default: false,
    },
    c: {
      type: 'string',
      demandOption: false,
      alias: 'config-file',
      describe: 'config file path',
    },
  })
  .epilog('Scans a directory for bidirectional Trojan Source attacks.')
  .parseSync(process.argv.slice(2));

export default getCommandOptions;
