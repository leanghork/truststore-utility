FROM alpine:3.21.3

# Install pre-requisite : bash, coreutils, openssl
RUN apk add bash coreutils openssl

# Create working directory
RUN mkdir -p /app/script /app/workspace 

# Adding timezone info and defaulting to Singapore Time
ADD timezone/zoneinfo/Asia/Singapore /etc/localtime
ADD timezone/timezone /etc/timezone

# Application configuration
ADD script /app/script
ENV PATH="/app/script/:$PATH"

WORKDIR /app/workspace

ENTRYPOINT ["truststore.sh"]
