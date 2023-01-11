/* eslint-disable no-console */
// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';

const initializeLogging = () => ({
  error: (message) => {
    // log to plain console and create a GitHub annotation
    console.error(message);
    core.error(message);
  },
  warn: (message) => {
    // log to plain console and create a GitHub annotation
    console.warn(message);
    core.warning(message);
  },
  info: (message) => {
    // core.notice will output an annotation, but we just want basic console logging for this
    console.info(message);
  },
  debug: (message) => {
    core.debug(message);
  },
});

// eslint-disable-next-line import/prefer-default-export
export { initializeLogging };
