# Portainer Endpoint

[![](https://images.microbadger.com/badges/image/softonic/portainer-endpoint.svg)](https://microbadger.com/images/softonic/portainer-endpoint "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/softonic/portainer-endpoint.svg)](https://microbadger.com/images/softonic/portainer-endpoint "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/commit/softonic/portainer-endpoint.svg)](https://microbadger.com/images/softonic/portainer-endpoint "Get your own commit badge on microbadger.com")

This image allows to auto register all the swarm nodes in a Portainer running in the same cluster and network.

## The goal

Currently when running under `Docker Swarm mode` portainer has visibility of services and their tasks, but from the task you cannot get the logs/ssh session/etc.

In the container tab you have only access to the containers running in the host where Portainer is connected. In case you want to get this functionality on containers running on other nodes of the cluster you need to add manually the connection details, which is not a valid solution in an elastic swarm cluster where nodes are added and removed continuously.

This image allows you to make automatic this process.

## How to use

You need to create a global service and pass some options and env vars.

Thanks to the "global service" concept in Swarm mode we can run a service ensuring that each node is running a service task. In case the cluster adds more nodes Swarm is the responsible of launch a new task in the node, it's totally automatic.

### Options
- Network: It's important to attach this service in a network where Portainer is attached.
- Mounts
    - Hostname file: This allows to detect the name of the host where the service task is running.
    - Docker socket: This allows to expose the socket to Portainer.

### Environment Variables

- `HOST_HOSTNAME`:   (Optional) Just in case you want to change the mount point of the file that contains the name of the host
- `PORTAINER_ADDR`:  Name and port where Portainer is configured
- `PORTAINER_USER`:  Username used to login to Portainer
- `PORTAINER_PASS`:  Password used to login to Portainer
- `SSL_IGNORE_CERTIFICATION_CHECK`: Activate it in case you don't want to validate the certificate in the Portainer service
- `SLEEP_IF_WORKER`: Seconds to wait before register the node if it's a worker

The `SLEEP_IF_WORKER` is useful to avoid that a worker is the first to register to Portainer, because it loads by default
the first registered endpoint, if it's a worker you won't have the cluster overview in a first sight.

### Example of use as a container

This allows to register just the current node. You need to be sure that the `portainer` network is attachable.

``` bash
docker container run \
  --name portainer-endpoint \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --mount type=bind,source=/etc/hostname,target=/etc/host_hostname \
  --network portainer \
  --hostname="{{.Node.Hostname}} \
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
  --hostname="{{.Node.Hostname}} \
  --network portainer \
  --mode global \
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

Once the stack is deployed and running you can go to the port `9000` on any of your cluster nodes to reach Portainer.
You'll see all the nodes in your cluster are already registered.

#### Requirements

- It needs Docker >17.04 because of the version of the stack file
- It needs Docker >17.10.0 for get rid of the host name mounted as a volume (`--mount type=bind,source=/etc/hostname,target=/etc/host_hostname`) and the `-e HOST_HOSTNAME=/etc/host_hostname` variable. 
- In this example I'm using a secret for the Portainer password in the endpoints
- Its usage is optional, you can use the environment variable with the password in clear text (not recommended)
