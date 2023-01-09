// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { readdirSync, readFileSync } from 'fs';
import path from 'path';
import { hasTrojanSource } from 'anti-trojan-source'

import { Logger } from './logger.js';

const scanDirectory = (directory, recursive, config) => {
  let found = false;

  const files = readdirSync(directory, { withFileTypes: true });
  files.forEach((fsEntry) => {
    if (fsEntry.isFile()) {
      const fullPath = path.join(directory, fsEntry.name)
      Logger.info(`Scanning file ${fullPath}`);

      const isDangerous = hasTrojanSource({ sourceText: readFileSync(fullPath) });
      if (isDangerous){
        Logger.error(`File '${fullPath}' contains bidirectional characters / possible Trojan Source attack.`);
        found = true;
      }
    }
    else if (fsEntry.isDirectory() && recursive) {
      const fullPath = path.join(directory, fsEntry.name)
      found = scanDirectory(fullPath, recursive) || found;
    }
  });

  return found;
};

export default scanDirectory;
