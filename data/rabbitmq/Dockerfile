ARG RABBITMQ_VERSION=3.13.0
FROM rabbitmq:${RABBITMQ_VERSION}-management

# The delayed message exchange plugin version has to match the RabbitMQ version
ARG RABBITMQ_VERSION
ARG DELAYED_MESSAGE_PLUGIN_VERSION=${RABBITMQ_VERSION}

ADD --chmod=644 \
    "https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_PLUGIN_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_PLUGIN_VERSION}.ez" \
    /opt/rabbitmq/plugins/

RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange

# Expose necessary ports
EXPOSE 15672 5672
