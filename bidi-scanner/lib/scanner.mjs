// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { lstatSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import glob from 'glob';
import { hasTrojanSource } from './detector.mjs';

const scanDirectory = (directory, recursive, ignore, logger) => {
  let found = false;

  let root = resolve(recursive ? join(directory, '**') : join(directory, '*'));
  logger.info(`Scanning from '${root}'`);

  // glob doesn't like backslashes on Windows
  root = root.replace(/\\/g, '/');

  const files = glob.sync(root, { ignore });
  files.forEach((fullPath) => {
    if (lstatSync(fullPath).isFile()) {
      logger.info(`Scanning file ${fullPath}`);

      const isDangerous = hasTrojanSource({ sourceText: readFileSync(fullPath) });
      if (isDangerous) {
        logger.error(`File '${fullPath}' contains bidirectional characters / possible Trojan Source attack.`);
        found = true;
      }
    }
  });

  return found;
};

export { scanDirectory };
