/* Adapted from:code with original license:

Copyright 2021 Liran Tal <liran.tal@gmail.com>.

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy
of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.
*/

import { dangerousBidiChars } from './constants.mjs';

// Returns an array of { char, codePoint, line, column } for every bidi character
// found. An empty array means the file is clean.
function hasTrojanSource({ sourceText }) {
  const lines = sourceText.toString().split('\n');
  const findings = [];

  lines.forEach((lineText, lineIndex) => {
    dangerousBidiChars.forEach((bidiChar) => {
      let col = lineText.indexOf(bidiChar);
      while (col !== -1) {
        findings.push({
          char: bidiChar,
          codePoint: `U+${bidiChar.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')}`,
          line: lineIndex + 1,
          column: col + 1,
        });
        col = lineText.indexOf(bidiChar, col + 1);
      }
    });
  });

  return findings;
}

export { hasTrojanSource };
