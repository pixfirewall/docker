FROM alpine:3.24

# the alpine package version follows the base image
# hadolint ignore=DL3018
RUN apk add --no-cache opensmtpd

COPY smtpd.conf /etc/smtpd/smtpd.conf

EXPOSE 25

CMD ["smtpd", "-d", "-f", "/etc/smtpd/smtpd.conf"]
