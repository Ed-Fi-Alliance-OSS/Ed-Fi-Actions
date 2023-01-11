// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

const NoOpLogger = {
  fatal: (_message, _err) => {
    // do nothing
  },
  error: (_message, _err) => {
    // do nothing
  },
  warn: (_message) => {
    // do nothing
  },
  info: (_message, _extra) => {
    // do nothing
  },
  debug: (_message, _extra) => {
    // do nothing
  },
  trace: (_message) => {
    // do nothing
  },
  child: () => NoOpLogger,
};

let singletonLogger = NoOpLogger;

const setLogger = (logger) => singletonLogger = logger;

export {
  singletonLogger as Logger,
  setLogger
};
