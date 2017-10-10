#!/bin/sh -e

# Using curl instead of httpie for reduce the image size.

echo
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done

if [ -z ${HOST_HOSTNAME+x} ]; then
  echo "Environment variable 'HOST_HOSTNAME' not set, we'll use the container hostname instead"
  host_hostname=$(hostname)
else
  host_hostname=$(cat ${HOST_HOSTNAME})
fi

insecure_request=''
if [[ -n ${SSL_IGNORE_CERTIFICATION_CHECK} ]]; then
  insecure_request=' -k'
fi

# Obtain NodeID from docker socket
node_id=$(curl -s --unix-socket /var/run/docker.sock http:/v1.27/info | jq -r '.Swarm.NodeID')
if [ -n "$node_id" ]; then
  is_manager=$(curl -s --unix-socket /var/run/docker.sock http:/v1.27/info | jq --arg NodeID "$node_id" -c '.Swarm.RemoteManagers[] | select(.NodeID  | contains($NodeID))')
  if [[ -z "$is_manager" ]]; then
    echo "Sleeping ${SLEEP_IF_WORKER} seconds because the node is not a manager"
    sleep ${SLEEP_IF_WORKER}
  else
    echo "This node is manager, don't sleep!"
  fi
fi

# Get Portainer JWT
#jwt=$(http POST "${PORTAINER_ADDR}/api/auth" Username="${PORTAINER_USER}" Password="${PORTAINER_PASS}" | jq -r .jwt)
jwt=$(curl -sf${insecure_request} -X POST -H "Accept: application/json, */*" -H "Content-Type: application/json" --data "{\"Username\": \"${PORTAINER_USER}\", \"Password\": \"${PORTAINER_PASS}\"}" "${PORTAINER_ADDR}/api/auth"  | jq -r .jwt)

[ -z "$jwt" ] && echo "Can't connect or login with Portainer" && exit 1

# Check if the host is already registered
# registered_hosts=$(http --auth-type=jwt --auth="${jwt}" ${PORTAINER_ADDR}/api/endpoints | jq --arg HOST "$host_hostname" -c '.[] | select(.Name == $HOST) | .Id')
registered_hosts=$(curl -sf${insecure_request} -X GET -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" ${PORTAINER_ADDR}/api/endpoints | jq --arg HOST "$host_hostname" -c '.[] | select(.Name == $HOST) | .Id')
for i in $registered_hosts
do
  echo Deleting previous found host name with id $i
  # http --auth-type=jwt --auth="${jwt}" DELETE ${PORTAINER_ADDR}/api/endpoints/$i
  curl -sf${insecure_request} -X DELETE -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" ${PORTAINER_ADDR}/api/endpoints/${i}
done

# Register current host
# http --auth-type=jwt --auth="${jwt}" POST ${PORTAINER_ADDR}/api/endpoints Name="${host_hostname}-endpoint" URL="tcp://${HOSTNAME}:2375"
curl -sf${insecure_request} -X POST -H "Accept: application/json, */*" -H "Content-Type: application/json" -H "Authorization: Bearer ${jwt}" --data "{\"Name\": \"${host_hostname}\", \"URL\": \"tcp://${HOSTNAME}:2375\"}" ${PORTAINER_ADDR}/api/endpoints

exec "$@"

