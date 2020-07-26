ARG ELIXIR_VERSION=1.10-alpine
ARG ALPINE_VERSION=3.11

# --------------------------------------------------------------------------- #
FROM elixir:${ELIXIR_VERSION} as build

# install build dependencies
RUN apk add --update git build-base nodejs npm

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force &&\
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

COPY config /app/config
COPY mix.exs /app/
COPY mix.lock /app/
COPY apps /app/apps
COPY rel /app/apps

# install mix dependencies
RUN mix deps.get --only prod

# build
RUN mix compile

# install & update JavaScript dependencies, compile assets
WORKDIR /app/apps/xomium_web
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

WORKDIR /app
RUN mix release

# --------------------------------------------------------------------------- #
FROM alpine:${ALPINE_VERSION} AS app
RUN apk add --update bash

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/xomium_umbrella ./
RUN chown -R nobody: /app
USER nobody

EXPOSE 4000

# docker run -p 4000:4000 -e SECRET_KEY_BASE=${SECRET_KEY_BASE} xomium_umbrella
# docker run -it -p 4000:4000 -e SECRET_KEY_BASE=${SECRET_KEY_BASE} xomium_umbrella start_iex
ENTRYPOINT ["./bin/xomium_umbrella"]
CMD ["start"]
