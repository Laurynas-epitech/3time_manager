FROM elixir:1.17-alpine

RUN apk add --no-cache \
    build-base \
    git \
    postgresql-client

WORKDIR /app

COPY mix.exs mix.lock ./

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get
RUN mix deps.compile

COPY . .

RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]