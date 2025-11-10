# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

FROM python:3.11-alpine3.20@sha256:95040093b88eea0af546de5a6e7c714f976b0e5c8e79cc104df8f796354eb276

RUN mkdir /app
COPY ./ /app/

# Create virtual environment and install dependencies
# When building this container inside a network that re-encrypts certificates, 
# the certificate check will fail. Use the ARG below to trigger an override 
# of the certificate. Set TRUST_CERT=1 to enable certificate override.
ARG TRUST_CERT=0
RUN python -m venv /app/.venv \
    && if [ $TRUST_CERT -eq 1 ]; then \
         /app/.venv/bin/pip install --no-cache-dir --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r /app/requirements.txt; \
       else \
         /app/.venv/bin/pip install --no-cache-dir -r /app/requirements.txt; \
       fi

ENTRYPOINT ["sh", "/app/entrypoint.sh"]
