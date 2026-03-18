// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { error as coreError, warning, debug } from '@actions/core';

const initializeLogging = () => ({
  error: (message) => {
    // log to plain console and create a GitHub annotation
    console.error(message);
    coreError(message);
  },
  warn: (message) => {
    // log to plain console and create a GitHub annotation
    console.warn(message);
    warning(message);
  },
  info: (message) => {
    // core.notice will output an annotation, but we just want basic console logging for this
    console.info(message);
  },
  debug: (message) => {
    debug(message);
  },
});

export { initializeLogging };
