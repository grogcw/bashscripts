#!/usr/bin/env bash

# Manage domains on both Pi-hole and Nginx Proxy Manager
#
# Usage:
#	 To add a domain:
#			 ./manage_domains.sh add http(s)://<ip>:<port> domain.ext
#
#	 To delete a domain:
#			 ./manage_domains.sh delete domain.ext
#
#	 To check certificates:
#			 ./manage_domains.sh check_certs
#


# Configuration (adjust as needed):
NGINX_EMAIL="your@mail.com"
NGINX_PASSWORD="your_nginx_password"
NGINX_HOST="your_nginx_instance_FQDN_or_ip"	    # (for token retrieval; no scheme here)
NGINX_IP="192.168.0.254"					    # The IP used in the Pi-hole DNS record

PIHOLE_PASSWORD="your_nginx_password"
PIHOLE_HOST="your_pihole_instance_FQDN_or_ip"


###############################################
# Check for required commands
###############################################
check_dependencies() {
	for cmd in curl jq; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo "Error: Required command '$cmd' is not installed. Please install it." >&2
			exit 1
		fi
	done
}

check_dependencies


###############################################
# Usage function
###############################################
usage() {
	echo "Usage:"
	echo "	To add a domain:		$0 add http(s)://<ip>:<port> domain.ext"
	echo "	To delete a domain: $0 delete domain.ext"
	echo "	To check certificates: $0 check_certs"
	exit 1
}


###############################################
# Argument Parsing
###############################################
if [ "$#" -eq 0 ]; then
	usage
fi

if [ "$1" = "check_certs" ]; then
	ACTION="check_certs"
elif [ "$#" -eq 1 ]; then
	usage
elif [ "$#" -eq 2 ]; then
	if [ "$1" = "delete" ]; then
		ACTION="delete"
		DOMAIN="$2"
	else
		usage
	fi
elif [ "$#" -eq 3 ]; then
#elif [ "$#" -eq 3 ]; then                     # Uncomment if you have multiple certificates to choose from.
	if [ "$1" = "add" ]; then
		ACTION="add"
		URL="$2"
		DOMAIN="$3"
		CERT_ID="1"			                   # Certificate ID to automatically use it for SSL termination. Check yours by running the script with check_certs
#		 CERT_ID="$4"	                       # Uncomment if you have multiple certificates to choose from.
	else
		usage
	fi
else
	usage
fi


###############################################
# Nginx Proxy Manager Functions
###############################################

get_nginx_token() {
	local resp token
	resp=$(curl -s -X POST "https://${NGINX_HOST}/api/tokens" \
			-H "Content-Type: application/json" \
			-d "{\"identity\": \"${NGINX_EMAIL}\", \"secret\": \"${NGINX_PASSWORD}\"}")
	token=$(echo "$resp" | jq -r '.token')
	if [ -z "$token" ] || [ "$token" = "null" ]; then
			echo "Failed to retrieve Nginx token." >&2
			exit 1
	fi
	echo "$token"
}


add_nginx_domain() {
	local token scheme rest forward_host forward_port payload response
	token=$(get_nginx_token)

	# Parse URL: expecting format http(s)://<ip>:<port>
	scheme="${URL%%://*}"
	rest="${URL#*://}"
	forward_host="${rest%%:*}"
	forward_port="${rest#*:}"

	# Validate that PORT is numeric and within 1-65535
	if ! [[ $forward_port =~ ^[0-9]+$ ]]; then
		echo "Error: Port '$forward_port' is not a valid number." >&2
		exit 1
	fi
	if [ "$forward_port" -lt 1 ] || [ "$forward_port" -gt 65535 ]; then
		echo "Error: Port must be between 1 and 65535, got '$forward_port'." >&2
		exit 1
	fi

	payload=$(cat <<EOF
{
	"domain_names": ["${DOMAIN}"],
	"forward_scheme": "${scheme}",
	"forward_host": "${forward_host}",
	"forward_port": ${forward_port},
	"certificate_id": ${CERT_ID},
	"ssl_forced": false,
	"hsts_enabled": false,
	"hsts_subdomains": false,
	"http2_support": false,
	"caching_enabled": false,
	"block_exploits": false,
	"advanced_config": "",
	"enabled": true,
	"meta": {}
}
EOF
)
	response=$(curl -s -X POST "http://${NGINX_HOST}/api/nginx/proxy-hosts" \
			-H "Authorization: Bearer ${token}" \
			-H "Content-Type: application/json" \
			-d "${payload}")
	echo "Nginx add response:"
	echo "${response}"
}


delete_nginx_domain() {
	local token matches num_matches host_id response search_term
	token=$(get_nginx_token)
	search_term="${DOMAIN}"
	response=$(curl -s -X GET "http://${NGINX_HOST}/api/nginx/proxy-hosts" \
			-H "Authorization: Bearer ${token}" \
			-H "Content-Type: application/json")
	matches=$(echo "$response" | jq --arg search "$search_term" '[.[] | select(.domain_names[] | contains($search))]')
	num_matches=$(echo "$matches" | jq 'length')
	if [ "$num_matches" -eq 0 ]; then
		echo "No proxy hosts found containing '$search_term'." >&2
		exit 0
	elif [ "$num_matches" -gt 1 ]; then
		echo "Multiple matching hosts found. Please refine your search term." >&2
		echo "$matches" | jq '.[] | {id, domain_names}'
		exit 1
	else
		host_id=$(echo "$matches" | jq '.[0].id')
		echo "Deleting Nginx proxy host with ID ${host_id}..."
		response=$(curl -s -X DELETE "http://${NGINX_HOST}/api/nginx/proxy-hosts/${host_id}" \
				 -H "Authorization: Bearer ${token}" \
				 -H "Content-Type: application/json")
		echo "Nginx delete response:"
		echo "${response}"
	fi
}


check_nginx_certs() {
	local token resp
	token=$(get_nginx_token)
	resp=$(curl -s -X GET "http://${NGINX_HOST}/api/nginx/certificates?expand=owner" \
				 -H "Authorization: Bearer ${token}" \
				 -H "Content-Type: application/json")
	echo "Certificates:"
	echo "$resp" | jq .
}


###############################################
# Pi-hole Functions
###############################################

get_pihole_tokens() {
	local auth_json sid csrf
	auth_json=$(curl -s -X POST "https://${PIHOLE_HOST}/api/auth" \
			-H 'accept: application/json' \
			-H 'content-type: application/json' \
			-d "{\"password\":\"${PIHOLE_PASSWORD}\"}")
	sid=$(echo "$auth_json" | jq -r '.session.sid')
	csrf=$(echo "$auth_json" | jq -r '.session.csrf')
	if [ -z "$sid" ] || [ "$sid" = "null" ]; then
		echo "Pi-hole authentication failed." >&2
		exit 1
	fi
	echo "$sid;$csrf"
}


add_pihole_domain() {
	local tokens sid csrf url result
	tokens=$(get_pihole_tokens)
	sid="${tokens%%;*}"
	csrf="${tokens#*;}"
	url="https://${PIHOLE_HOST}/api/config/dns/hosts/${NGINX_IP}%20${DOMAIN}"
	result=$(curl -s -X PUT "$url" \
		-H 'content-type: application/json' \
		-d "{\"sid\":\"${sid}\"}" \
		-d "{\"csrf\":\"${csrf}\"}")
	echo "Pi-hole add response:"
	echo "${result}"
}


delete_pihole_domain() {
	local tokens sid csrf url result
	tokens=$(get_pihole_tokens)
	sid="${tokens%%;*}"
	csrf="${tokens#*;}"
	url="https://${PIHOLE_HOST}/api/config/dns/hosts/${NGINX_IP}%20${DOMAIN}"
	result=$(curl -s -X DELETE "$url" \
		-H 'content-type: application/json' \
		-d "{\"sid\":\"${sid}\"}" \
		-d "{\"csrf\":\"${csrf}\"}")
	echo "Pi-hole delete response:"
	echo "${result}"
}


###############################################
# Main Execution
###############################################
case "$ACTION" in
	add)
		echo "Adding domain '${DOMAIN}'..."
		add_nginx_domain
		add_pihole_domain
		;;
	delete)
		echo "Deleting domain '${DOMAIN}'..."
		delete_nginx_domain
		delete_pihole_domain
		;;
	check_certs)
		echo "Checking certificates..."
		check_nginx_certs
		;;
	*)
		usage
		;;
esac
