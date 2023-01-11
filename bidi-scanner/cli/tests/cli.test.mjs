// SPDX-License-Identifier: Apache-2.0
// Licensed to the Ed-Fi Alliance under one or more agreements.
// The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
// See the LICENSE and NOTICES files in the project root for more information.

import { resolve, join, dirname } from 'path';
// eslint-disable-next-line import/no-extraneous-dependencies
import { jest } from '@jest/globals';
import { fileURLToPath } from 'url';
import { processFiles } from '../cli.mjs';

const filename = fileURLToPath(import.meta.url);
const thisDirectory = dirname(filename);

const mockLogger = {
  fatal: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn(),
  trace: jest.fn(),
  child: () => mockLogger,
  mockClear: () => {
    mockLogger.fatal.mockClear();
    mockLogger.error.mockClear();
    mockLogger.warn.mockClear();
    mockLogger.info.mockClear();
    mockLogger.debug.mockClear();
    mockLogger.trace.mockClear();
  },
};

describe('when testing for bidirectional (bidi) characters', () => {
  describe('given the input directory does not exist', () => {
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', 'fake']);
    });

    it('exits with code 2', () => {
      expect(exitCode).toBe(2);
    });

    it('logs to info', () => {
      expect(mockLogger.info).toHaveBeenCalled();
    });

    it('logs an error', () => {
      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('given valid arguments, default config, not recursive, and no bidi chars', () => {
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', resolve(join(thisDirectory, '..')), '-r', false]);
    });

    it('exits with code 0', () => {
      expect(exitCode).toBe(0);
    });

    it('logs to info', () => {
      expect(mockLogger.info).toHaveBeenCalled();
    });

    it('does not log any errors', () => {
      expect(mockLogger.error).not.toHaveBeenCalled();
    });
  });

  describe('given valid arguments, default config, and there is a bidi char in a js file', () => {
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', resolve(join(thisDirectory, 'true-trojan-js'))]);
    });

    it('exits with code 1', () => {
      expect(exitCode).toBe(1);
    });

    it('logs an error', () => {
      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('given valid arguments, default config, and there is a bidi char in an other file', () => {
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', resolve(join(thisDirectory, 'true-trojan-other'))]);
    });

    it('exits with code 1', () => {
      expect(exitCode).toBe(1);
    });

    it('logs an error', () => {
      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('given valid arguments, default config, and there is a bidi char in an ai file', () => {
    // *.ai is part of the default configuration and thus should be ignored.
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', resolve(join(thisDirectory, 'true-trojan-ai'))]);
    });

    it('exits with code 0', () => {
      expect(exitCode).toBe(0);
    });

    it('does not log an error', () => {
      expect(mockLogger.error).not.toHaveBeenCalled();
    });
  });

  describe('given valid arguments, custom globbed config, recursive, and there is a bidi char in an other file', () => {
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, [
        '-d',
        resolve(join(thisDirectory, 'true-trojan-other')),
        '-c',
        resolve(join(thisDirectory, 'custom-globbed.json')),
        '-r',
        'true',
      ]);
    });

    it('exits with code 0', () => {
      expect(exitCode).toBe(0);
    });

    it('does not log an error', () => {
      expect(mockLogger.error).not.toHaveBeenCalled();
    });
  });

  describe('given valid arguments, custom globbed config, recursive, and there is a bidi char in a nested other file', () => {
    // This is really testing the globbing - the "globbed" custom file excludes
    // *.other in _all_ directories
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, [
        '-d',
        resolve(join(thisDirectory, 'nesting')),
        '-c',
        resolve(join(thisDirectory, 'custom-globbed.json')),
        '-r',
        'true',
      ]);
    });

    it('exits with code 0', () => {
      expect(exitCode).toBe(0);
    });

    it('does not log an error', () => {
      expect(mockLogger.error).not.toHaveBeenCalled();
    });
  });

  describe('given valid arguments, custom flat config, recursive, and there is a bidi char in a nested other file', () => {
    // This is really testing the globbing - the "flat" custom file excludes
    // *.other only in parent dir, but the error is nested. Thus the scanner
    // should flag this error.
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, [
        '-d',
        resolve(join(thisDirectory, 'nesting')),
        '-c',
        resolve(join(thisDirectory, 'custom-flat.json')),
        '-r',
        'true',
      ]);
    });

    it('exits with code 1', () => {
      expect(exitCode).toBe(1);
    });

    it('logs an error', () => {
      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('given valid arguments, default config, not recursive, and there is a bidi char in a nested other file', () => {
    // Unlike the prior test, recursion is disabled - thus the scanner will
    // never see the nested file and simply does not test it.
    let exitCode = 0;

    beforeAll(async () => {
      mockLogger.mockClear();

      exitCode = processFiles(mockLogger, ['-d', resolve(join(thisDirectory, 'nesting')), '-r', 'false']);
    });

    it('exits with code 0', () => {
      expect(exitCode).toBe(0);
    });

    it('logs an error', () => {
      expect(mockLogger.error).not.toHaveBeenCalled();
    });
  });
});
