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

function hasTrojanSource({ sourceText }) {
  const sourceTextToSearch = sourceText.toString();

  let found = false;
  dangerousBidiChars.every((bidiChar) => {
    if (sourceTextToSearch.includes(bidiChar)) {
      found = true;
      return false;
    }
    return true;
  });

  return found;
}

export { hasTrojanSource };
