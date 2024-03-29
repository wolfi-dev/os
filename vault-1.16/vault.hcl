/*
 * Vault configuration. See: https://www.vaultproject.io/docs/configuration
 */

storage "file" {
	path = "/var/lib/vault"
}

listener "tcp" {
	/*
	 * By default Vault listens on localhost only.
	 * Make sure to enable TLS support otherwise.
	 */
	tls_disable = 1
}

api_addr = "http://127.0.0.1:8200"
