#!/bin/bash
#
# GitHub App credentials
APP_ID=$APP_ID                   # Replace with your GitHub App's ID
INSTALLATION_ID=$INSTALLATION_ID # Replace with the installation ID for your app
PRIVATE_KEY_PATH="./key.pem"     # Replace with the path to your GitHub App's private key

# Function to generate a JWT
generate_jwt() {
	local issuer="$APP_ID"
	local issued_at=$(date +%s)
	local expiration=$(($issued_at + 600)) # JWT valid for 10 minutes
	local header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
	local payload=$(echo -n "{\"iat\":$issued_at,\"exp\":$expiration,\"iss\":\"$issuer\"}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
	local unsigned_token="$header.$payload"
	local signature=$(echo -n "$unsigned_token" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

	echo "$unsigned_token.$signature"
}

# Function to get an installation access token
get_installation_token() {
	local jwt="$1"
	local token_url="https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens"
	local token_response=$(curl -X POST -H "Authorization: Bearer $jwt" -H "Accept: application/vnd.github+json" "$token_url")
	echo $token_response | jq -r '.token'
}

# Main script execution
jwt=$(generate_jwt)
installation_token=$(get_installation_token "$jwt")

echo "new jwt token : $jwt"
echo "new gh token  : $installation_token"

kubectl version --client
helm version --client

# Use the installation token instead of a PAT for runner registration
GH_TOKEN=$installation_token
GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="runnner-${RUNNER_SUFFIX}"

REG_TOKEN=$(curl -L \
	-X POST \
	-H "Accept: application/vnd.github+json" \
	-H "Authorization: Bearer $GH_TOKEN" \
	-H "X-GitHub-Api-Version: 2022-11-28" \
	https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

cd /actions-runner

./config.sh --unattended --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME} --labels ${GH_REPOSITORY} 

cleanup() {
	echo "Removing runner..."
	./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh &
wait $!
