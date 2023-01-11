// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';
import { setLogger } from './logger.mjs';

let isInitialized = false;

export const initializeLogging = () => {
  if (isInitialized) return;

  const GitHubLogger = {
    error: (message) => {
      core.error(message);
    },
    warn: (message) => {
      core.warning(message);
      logger.warn({ message });
    },
    info: (message) => {
      core.notice(message);
    },
    debug: (message) => {
      core.debug(message);
    },
  };
  setLogger(GitHubLogger);
};

