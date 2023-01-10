// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import winston from 'winston';

const timestampFormat = 'YYYY-MM-DD HH:mm:ss.SSS';

const format = winston.format.combine(
  winston.format.timestamp({
    format: timestampFormat,
  }),
  winston.format.printf(({
    level, message, timestamp, extra, err,
  }) => {
    const m = message;
    let e = err ?? extra ?? '';

    if (typeof e === 'object') {
      e = JSON.stringify(e);
    }

    return `${timestamp} ${level} ${m} ${e}`;
  }),
  winston.format.colorize({
    all: true,
  }),
);

// Logger begins life "uninitialized" and in silent mode
let isInitialized = false;

// Create and set up a silent default logger transport - in case a library is
// using the default logger
const transport = new winston.transports.Console();
transport.silent = true;
winston.configure({ transports: [transport] });

// Set initial logger to silent
let logger = winston.createLogger({
  transports: [transport],
});

export const initializeLogging = () => {
  if (isInitialized) return;

  const offline = process.env.IS_LOCAL === 'true';
  isInitialized = true;
  logger = winston.createLogger({
    level: process.env.LOG_LEVEL?.toLocaleLowerCase() ?? (offline ? 'debug' : 'info'),
    transports: [
      new winston.transports.Console({
        format,
      }),
    ],
  });
};

export const Logger = {
  fatal: (message, err) => {
    logger.error({ message: `💥 ${message}`, err });
  },
  error: (message, err) => {
    logger.error({ message, err });
  },
  warn: (message) => {
    logger.warn({ message });
  },
  info: (message, extra) => {
    logger.info({ message, extra });
  },
  debug: (message, extra) => {
    logger.debug({ message, extra });
  },
  trace: (message) => {
    logger.debug({ message: JSON.stringify(message) });
  },
  child: () => Logger,
};
