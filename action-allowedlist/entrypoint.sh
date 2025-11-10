#
# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
#

location=$PWD
cd /app > /dev/null

# Run the application using the virtual environment
/app/.venv/bin/python action_allowedlist $location "/app/approved.json"
