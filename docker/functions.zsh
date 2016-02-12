docker-stats() {
    docker stats $(docker inspect -f "{{ .Name }}" $(docker ps -q))
}

docker-start() {
    docker-machine start default
    docker-envs
}

docker-stop() {
    docker-machine stop default
    unset DOCKER_TLS_VERIFY
    unset DOCKER_HOST
    unset DOCKER_CERT_PATH
    unset DOCKER_MACHINE_NAME
}

docker-init() {
    docker-machine kill default
    docker-machine rm default
    docker-machine create --driver=parallels default
    docker-envs
}

docker-envs() {
    eval $(docker-machine env default)
}
