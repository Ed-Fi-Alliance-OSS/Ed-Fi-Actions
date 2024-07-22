#
# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
#

location=$PWD
cd /app > /dev/null

# Poetry is installed here
export PATH="/root/.local/bin:$PATH"

# Change the cache directory to the one used in the Dockerfile build
poetry config cache-dir /var/cache/pypoetry

poetry run python action_allowedlist $location "/app/approved.json"
