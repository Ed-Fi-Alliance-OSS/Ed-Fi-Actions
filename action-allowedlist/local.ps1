# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

# Use for building the image locally while on the internal office network
docker buildx build -t local/action-allowedlist --build-arg="TRUST_CERT=1" .
docker run local/action-allowedlist
