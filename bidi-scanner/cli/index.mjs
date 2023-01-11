// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { hideBin } from 'yargs/helpers';

import { processFiles } from './cli.mjs';
import { initializeLogging } from './winstonLogger.mjs';

const logger = initializeLogging();

const args = hideBin(process.argv);
const exitCode = processFiles(logger, args);

process.exit(exitCode);
