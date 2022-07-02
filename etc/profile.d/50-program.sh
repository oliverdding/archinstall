export DOCKER_BUILDKIT="1"
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export GOPROXY="https://goproxy.io,direct"
export SBT_OPTS="-Dsbt.override.build.repos=true"
