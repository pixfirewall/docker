FROM kong:3.7.1-ubuntu
# FROM kong:2.8-ubuntu
# FROM kong/kong-gateway:3.0

USER root

RUN apt-get update && apt-get install -y git unzip

RUN git clone https://github.com/pixfirewall/kong-oidc.git

WORKDIR /kong-oidc
RUN luarocks make

# RUN luarocks install kong-oidc

# RUN luarocks install kong-plugin-oidc

USER kong