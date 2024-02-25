  #!/bin/bash

  KEYCLOAK_URL="http://localhost:8080"
  REALM=""
  CLIENT_ID=""
  CLIENT_SECRET=""
  REDIRECT_URI="http://localhost:3000/"
  SCOPE="openid email profile"
  CODE_CHALLENGE_METHOD="S256"
  CODE_CHALLENGE=""
  CODE_VERIFIER=""
  STATE=""
  AUTHORIZATION_CODE=""
  PORT=3000


  generate_code_challenge_and_verifier() {
      CODE_VERIFIER=$(openssl rand -hex 32)
      CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -binary -sha256 | openssl enc -base64 | tr -d '\n\r=' | tr '/+' '_-')
  }
 
  open_login_url(){
     LOGIN_URL="$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/auth?client_id=$CLIENT_ID&scope=$SCOPE&response_type=code&redirect_uri=$REDIRECT_URI&state=$STATE&code_challenge=$CODE_CHALLENGE&code_challenge_method=$CODE_CHALLENGE_METHOD"
     wslview "$LOGIN_URL" &
     sleep 2
  }

  stop_app_if_running() {
      PID_APP_NODE=$(lsof -ti tcp:$PORT)  

      if [ -n "$PID_APP_NODE" ]; then 
        kill $PID_APP_NODE
        echo "Aplicativo rodando na porta $PORT foi parado."
        sleep 2
      fi
  }


  start_node_server() {
    cd "./src" 
    npm run dev &
    sleep 2
  }


  get_authorization_code() {
      echo "Please enter the authorization code:" AUTHORIZATION_CODE 
      read AUTHORIZATION_CODE
  }


  exchange_code_for_token() {
      RESPONSE=$(curl -s -w "%{http_code}" -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -d "grant_type=authorization_code" \
          -d "client_id=$CLIENT_ID" \
          -d "client_secret=$CLIENT_SECRET" \
          -d "redirect_uri=$REDIRECT_URI" \
          -d "code_verifier=$CODE_VERIFIER" \
          -d "code=$AUTHORIZATION_CODE")
      
      HTTP_STATUS="${RESPONSE: -3}"  
      BODY="${RESPONSE:0:-3}"

      if [ "$HTTP_STATUS" -eq 200 ]; then
          ACCESS_TOKEN=$(echo "$BODY" | jq -r '.access_token')
          echo "Access Token: $ACCESS_TOKEN"
      else
          ERROR_MESSAGE=$(echo "$BODY" | jq -r '.error_description')
          echo "Error: $ERROR_MESSAGE (HTTP Status Code: $HTTP_STATUS)"
      fi
  }


  generate_code_challenge_and_verifier
  open_login_url
  stop_app_if_running
  start_node_server
  get_authorization_code
  exchange_code_for_token