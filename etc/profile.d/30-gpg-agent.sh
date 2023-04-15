if [[ ! -z ${SSH_AGENT_PID+x} ]]; then unset SSH_AGENT_PID; fi
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

export GPG_AGENT_INFO="$(gpgconf --list-dirs agent-socket):0:1"