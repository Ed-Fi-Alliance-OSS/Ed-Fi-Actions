// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import core from '@actions/core';

const initializeLogging = () => ({
  error: (message) => {
    core.error(message);
  },
  warn: (message) => {
    core.warning(message);
  },
  info: (message) => {
    core.notice(message);
  },
  debug: (message) => {
    core.debug(message);
  },
});

// eslint-disable-next-line import/prefer-default-export
export { initializeLogging };
