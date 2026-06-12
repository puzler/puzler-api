# The SPA initiates OAuth with a plain link (GET). Authorization elsewhere is
# Bearer-JWT (no cookie auth on API requests), so login-CSRF via GET gains an
# attacker nothing; the OAuth state param still protects the callback phase.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
