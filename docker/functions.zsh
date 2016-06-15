docker-stats() {
    docker stats $(docker inspect -f "{{ .Name }}" $(docker ps -q))
}
