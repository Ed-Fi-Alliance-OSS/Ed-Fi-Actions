// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { statSync, readFileSync } from 'fs';
import { resolve } from 'path';
import { globSync } from 'glob';
import { hasTrojanSource } from './detector.mjs';

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

const scanDirectory = (directory, recursive, ignore, logger) => {
  let found = false;

  const root = resolve(directory);
  const pattern = recursive ? '**' : '*';
  logger.info(`Scanning from '${root}'`);

  // Pass `cwd: root` (rather than embedding the absolute path in the glob
  // pattern) so that glob's `ignore` matching - which resolves relative
  // patterns like `**/*.png` against the path relative to `cwd` - is anchored
  // to the scanned directory instead of the process's current working
  // directory. Otherwise, ignore patterns silently fail to match whenever the
  // scanned directory isn't an ancestor/descendant of process.cwd(), since
  // the resulting relative path (e.g. `../../other/file.cs`) can't match a
  // `**/...` glob.
  const files = globSync(pattern, { cwd: root, ignore, absolute: true });
  files.forEach((fullPath) => {
    // Use statSync (not lstatSync) so symlinks are followed rather than skipped
    const stat = statSync(fullPath);

    if (!stat.isFile()) return;

    if (stat.size > MAX_FILE_SIZE) {
      logger.warn(`Skipping '${fullPath}': file size ${stat.size} bytes exceeds ${MAX_FILE_SIZE}-byte limit`);
      return;
    }

    logger.debug(`Scanning file ${fullPath}`);

    const findings = hasTrojanSource({ sourceText: readFileSync(fullPath) });
    if (findings.length > 0) {
      findings.forEach(({ codePoint, line, column }) => {
        logger.error(
          `File '${fullPath}' line ${line}, col ${column}: bidirectional character ${codePoint} / possible Trojan Source attack.`,
        );
      });
      found = true;
    }
  });

  return found;
};

export { scanDirectory };
