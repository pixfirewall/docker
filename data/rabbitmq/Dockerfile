ARG RABBITMQ_VERSION=3.13.0
FROM rabbitmq:${RABBITMQ_VERSION}-management

ARG DELAYED_MESSAGE_PLUGIN_VERSION=3.13.0

# Ensure apt-get is up to date
RUN apt-get update && apt-get install -y wget

# Use the ARG in the wget command
RUN wget "https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_PLUGIN_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_PLUGIN_VERSION}.ez"

# Move the downloaded plugin to the plugins directory
RUN mv "rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_PLUGIN_VERSION}.ez" /opt/rabbitmq/plugins/

# Enable the plugin
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange

# Expose necessary ports
EXPOSE 15672 5672