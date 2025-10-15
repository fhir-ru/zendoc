# Stage 1: Dependencies cache
FROM clojure:temurin-17-tools-deps-alpine AS deps

WORKDIR /app

# Copy dependency files
COPY deps.edn bb.edn ./
COPY libs ./libs

# Download dependencies
RUN clojure -P -M:run

# Stage 2: Runtime
FROM clojure:temurin-17-tools-deps-alpine

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    bash

# Copy clojure dependencies cache from deps stage
COPY --from=deps /root/.m2 /root/.m2
COPY --from=deps /root/.gitlibs /root/.gitlibs

# Copy .git directory for git pull functionality
COPY .git/ .git/
COPY .gitmodules .gitmodules

# Configure git and pull latest docs from repository
RUN git remote set-url origin https://github.com/fhir-ru/zendoc.git && \
    git fetch origin && \
    git reset --hard origin/main && \
    git submodule update --init --recursive

# Copy project files (after git reset to override with local changes)
COPY deps.edn bb.edn zen.edn ./
COPY src ./src
COPY zrc ./zrc
COPY resources ./resources
COPY ftr ./ftr

# Copy entrypoint script
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Expose port
EXPOSE 3333

# Entrypoint
ENTRYPOINT ["./entrypoint.sh"]
