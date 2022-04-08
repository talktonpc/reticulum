FROM elixir:1.8-alpine as builder
RUN apk add --no-cache nodejs yarn git build-base
COPY . .
RUN mix local.hex --force && mix local.rebar --force && mix deps.get
RUN mix deps.clean mime --build && rm -rf _build && mix compile
RUN MIX_ENV=turkey mix distillery.release
RUN cp ./rel/config.toml ./_build/turkey/rel/ret/config.toml

FROM alpine/openssl as certr
WORKDIR certs
RUN openssl req -x509 -newkey rsa:2048 -sha256 -days 36500 -nodes -keyout key.pem -out cert.pem -subj '/CN=ret' && cp cert.pem cacert.pem

FROM alpine

RUN mkdir -p /storage && chmod 777 /storage
WORKDIR ret
COPY --from=builder /_build/turkey/rel/ret/ .
COPY --from=certr /certs .
RUN apk update && apk add --no-cache bash openssl-dev openssl jq libstdc++ git nodejs yarn elixir
COPY rel/.bashrc /root/.bashrc
COPY rel/hosts /etc/hosts
COPY scripts/docker/run.sh /run.sh
CMD bash /run.sh
