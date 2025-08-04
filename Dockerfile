ARG NODE_VERSION=22.16.0

FROM node:${NODE_VERSION}-alpine as base
RUN npm install pnpm turbo typescript --global
RUN pnpm config set store-dir ~/.pnpm-store
RUN pnpm config set strict-ssl false
# -----------------------------------------------------------------------------------
# Uncomment the following lines if you want to use a multi-stage build with a locker and pruner
# This is useful for CI builds and avoids the need to install nodeJS on the host.

# FROM base AS locker
# WORKDIR /app
# COPY . .
# RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --prefer-offline

# FROM base AS pruner
# ARG PROJECT
# WORKDIR /app
# COPY --from=locker /app ./
# RUN turbo prune --scope=${PROJECT} --docker
# -----------------------------------------------------------------------------------

FROM base AS pruner
ARG PROJECT
WORKDIR /app
COPY . .
RUN turbo prune --scope=${PROJECT} --docker

FROM base AS builder
ARG PROJECT
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app
# Copy lockfile and package.json's of isolated subworkspace
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
COPY --from=pruner /app/out/json/ .
# First install the dependencies (as they change less often)
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --frozen-lockfile --prefer-offline
# Copy source code of isolated subworkspace
COPY --from=pruner /app/out/full/ .
RUN turbo build --filter=${PROJECT}
# remove dev dependencies
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm prune --prod --no-optional 
RUN rm -rf ./**/*/src


FROM base AS runner
ARG PROJECT
ENV PROJECT=${PROJECT}
WORKDIR /app
COPY --from=builder --chown=node:node /app .
CMD turbo run ${PROJECT}#start --env-mode=loose

FROM base AS dev
ARG PROJECT
ENV PROJECT=${PROJECT}
ENV NODE_TLS_REJECT_UNAUTHORIZED=0
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
COPY --from=pruner /app/out/json/ .
RUN --mount=type=cache,id=pnpm,target=~/.pnpm-store pnpm install --prefer-offline
COPY --from=pruner /app/out/full/ .
WORKDIR /app/apps/${PROJECT}
#CMD npm run dev
#RUN turbo db:generate
#RUN turbo build --filter=${PROJECT}
CMD turbo watch ${PROJECT}#dev --env-mode=loose