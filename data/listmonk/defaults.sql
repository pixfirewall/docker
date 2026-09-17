-- Local development defaults for listmonk, applied by the listmonk-settings one-shot.
-- Only touches settings that still have the values of a fresh installation.

-- send through mailpit (http://localhost:8025)
UPDATE settings
SET value = '[{"host": "mailpit", "port": 1025, "enabled": true, "username": "", "password": "", "auth_protocol": "none", "tls_type": "none", "tls_skip_verify": true, "max_conns": 10, "idle_timeout": "15s", "wait_timeout": "5s", "max_msg_retries": 2, "email_headers": [], "hello_hostname": ""}]'
WHERE key = 'smtp' AND value::text LIKE '%smtp.yoursite.com%';

UPDATE settings SET value = '"http://localhost:8484"'
WHERE key = 'app.root_url' AND value::text = '"http://localhost:9000"';

UPDATE settings SET value = '"listmonk <noreply@example.test>"'
WHERE key = 'app.from_email' AND value::text LIKE '%listmonk.yoursite.com%';
