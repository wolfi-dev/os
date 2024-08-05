package authz
import rego.v1

test_post_allowed if {
	allow with input as {"path": ["users"], "method": "POST"}
}

test_get_anonymous_denied if {
	not allow with input as {"path": ["users"], "method": "GET"}
}

test_get_user_allowed if {
	allow with input as {"path": ["users", "bob"], "method": "GET", "user_id": "bob"}
}

test_get_another_user_denied if {
	not allow with input as {"path": ["users", "bob"], "method": "GET", "user_id": "alice"}
}