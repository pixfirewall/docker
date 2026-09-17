ARG KONG_VERSION=3.7.1-ubuntu
FROM kong:${KONG_VERSION}
# FROM kong:2.8-ubuntu
# FROM kong/kong-gateway:3.0

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/pixfirewall/kong-oidc.git /kong-oidc

WORKDIR /kong-oidc
# The global luarocks.org manifest has grown too large to be loaded by LuaJIT
# ("main function has more than 65536 constants"), so dependencies are resolved
# from the per-author manifests of the rocks kong-oidc needs instead.
RUN printf 'rocks_servers = { "%s", "%s" }\n' \
        https://luarocks.org/manifests/hanszandbelt \
        https://luarocks.org/manifests/cdbattags \
        > /tmp/luarocks-config.lua \
    && LUAROCKS_CONFIG=/tmp/luarocks-config.lua luarocks make \
    && rm /tmp/luarocks-config.lua

# RUN luarocks install kong-oidc

# RUN luarocks install kong-plugin-oidc

USER kong
