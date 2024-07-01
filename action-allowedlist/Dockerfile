# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

FROM python:3.9.19-alpine3.20@sha256:f2fffcd6d67fe80dbc4e82b49ab3797791aac8d6f2b9520426fc8b260cb47997

RUN mkdir /app
COPY ./ /app/

# Install Poetry. When building this container inside a network that re-encrypts
# certificates, the certificate check will fail. Use the ARG below to trigger an
# override of the certificate. Set TRUST_CERT=1 to enable certificat override.
ARG TRUST_CERT=0
RUN [ $TRUST_CERT -eq 0 ] \
        && CMD="wget -q -O - https://install.python-poetry.org | python" \
        || CMD="wget --no-check-certificate -q -O - https://install.python-poetry.org | python"; \
    eval $CMD \
    && export PATH="/root/.local/bin:$PATH" \
    && cd /app \
    && poetry install

ENV PATH="/root/.local/bin:$PATH"

ENTRYPOINT ["sh", "/app/entrypoint.sh"]
