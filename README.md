# Portainer Endpoint

This image allows to auto register all the swarm nodes in a portainer running in the same cluster and network.

## How to use

You need to create a global service and pass some options and env vars.

### Options
- Network: It's important to attach this service in a network where Portainer is attached.
- Mounts
    - Hostname file: This allows to detect the name of the host where the service task is running.
    - Docker socket: This allows to expose the socket to Portainer.

### Environment Variables

- HOST_HOSTNAME: (Optional) Just in case you want to change the mount point of the file that contains the name of the host
- PORTAINER_ADDR: Name and port where portainer is configured
- PORTAINER_USER: Username used to login to Portainer
- PORTAINER_PASS: Password used to login to Portainer

### Example of use as a container

This allows to register just the current node. You need to be sure that the `portainer` network is attachable.

``` bash
docker container run \
  --name portainer-endpoint \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --mount type=bind,source=/etc/hostname,target=/etc/host_hostname \
  --network portainer \
  -e HOST_HOSTNAME=/etc/host_hostname \
  -e PORTAINER_ADDR=portainer:9000 \
  -e PORTAINER_USER=admin \
  -e PORTAINER_PASS=12341234 \
  softonic/portainer-endpoint
```

### Example of use as a global service

This allows to register each node in Portainer.

``` bash
docker service create --with-registry-auth \
  --name portainer-endpoint \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --mount type=bind,source=/etc/hostname,target=/etc/host_hostname \
  --network portainer \
  --mode global \
  -e HOST_HOSTNAME=/etc/host_hostname \
  -e PORTAINER_ADDR=portainer:9000 \
  -e PORTAINER_USER=admin \
  -e PORTAINER_PASS=12341234 \
  softonic/portainer-endpoint
```

### Use in a stack with Portainer

You can use a Swarm Stack to deploy Portainer and the automatic registration feature. Just execute the stack file in a swarm cluster:

``` bash
git clone git@github.com:softonic/portainer-endpoint.git
cd portainer-endpoint
export VOLUME_DRIVER=local
export PORTAINER_PASS=12341234
export PORTAINER_ENC_PASS=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin ${PORTAINER_PASS} | cut -d ":" -f 2)
echo $PORTAINER_PASS | docker secret create portainer_password.v1 --label portainer -
docker stack deploy --compose-file docker-compose.yml portainer
```

Once the stack is deployed and running you can go to the port `9000` on any of your cluster nodes to reach portainer.
You'll see all the nodes in your cluster are already registered.

#### Requirements

- It needs Docker >17.04 because of the version of the stack file.
- In this example I'm using a secret for the portainer password in the endpoints.
- Its usage is optional, you can use the environment variable with the password in clear text (not recommended).
