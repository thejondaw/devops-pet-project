#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "\n${GREEN}=== $1 ===${NC}\n"
}

print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

setup_shell_aliases() {
    print_header "Setting up shell aliases"

    if grep -q "# === KUBERNETES ALIASES ===" ~/.bashrc; then
        print_info "Kubernetes aliases already exist in .bashrc"
        return 0
    fi

    cat << 'EOF' >> ~/.bashrc

# Basic kubectl
alias k="kubectl"
alias kc="kubectl config"
alias kcc="kubectl config current-context"
alias kcg="kubectl config get-contexts"
alias kcs="kubectl config set-context"
alias kcu="kubectl config use-context"

# Application Management
alias ka="kubectl apply -f"
alias kd="kubectl delete"
alias kdf="kubectl delete -f"
alias kdp="kubectl delete pod"

# Resource Information
alias kg="kubectl get"
alias kga="kubectl get all"
alias kgaa="kubectl get all --all-namespaces"
alias kgn="kubectl get nodes"
alias kgno="kubectl get nodes -o wide"
alias kgp="kubectl get pods"
alias kgpa="kubectl get pods --all-namespaces"
alias kgpo="kubectl get pods -o wide"
alias kgs="kubectl get services"
alias kgsa="kubectl get services --all-namespaces"

# Debugging & Monitoring
alias kl="kubectl logs"
alias klf="kubectl logs -f"
alias kpf="kubectl port-forward"
alias kex="kubectl exec -it"
alias kdesc="kubectl describe"
alias ktp="kubectl top pod"
alias ktn="kubectl top node"

# AWS - Aliases
alias awsid="aws sts get-caller-identity"
alias awsreg="aws configure get region"
alias awsls="aws ec2 describe-instances"

# Terraform - Aliases
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"
alias tfw="terraform workspace"

# Git - Aliases
alias gs="git status"
alias gp="git pull"
alias gf="git fetch"
alias gc="git checkout"
alias gb="git branch"
alias gl="git log --oneline --graph --decorate --all"

EOF

    source ~/.bashrc
    print_info "Shell aliases have been added to .bashrc and activated"
}

main() {
    print_header "Starting developer environment setup"

    setup_shell_aliases

    print_header "Setup completed successfully!"
    print_info "Please restart your terminal or run 'source ~/.bashrc' to apply changes"
}

main "$@"
