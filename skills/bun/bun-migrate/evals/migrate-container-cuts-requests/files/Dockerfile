FROM oven/bun:latest
WORKDIR /app
COPY . .
RUN bun install
# --smol = container mode (less memory)
CMD bun --smol src/index.ts
