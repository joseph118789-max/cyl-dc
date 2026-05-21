#!/bin/bash
# Daily health check for dining-feedback / DC infra services
# Run from openclaw01

LOGFILE="/var/log/health-check.log"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log() {
    echo "[$TIMESTAMP] $1" >> "$LOGFILE"
}

check_http() {
    local url=$1
    local name=$2
    local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
    if [ "$code" = "200" ]; then
        log "OK $name: $url → $code"
        return 0
    else
        log "FAIL $name: $url → $code"
        return 1
    fi
}

failed=0

# 1. K8s cluster nodes
log "=== Starting daily health check ==="

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 user@192.168.1.150 \
    "kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type==\"Ready\")].status}'" >> "$LOGFILE" 2>&1
if [ $? -eq 0 ]; then
    log "OK k3s nodes reachable"
else
    log "FAIL k3s nodes not reachable"
    failed=1
fi

# 2. k8s pods in dining-feedback namespace
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 user@192.168.1.150 \
    "kubectl get pods -n dining-feedback -o jsonpath='{range .items[*]}{.metadata.name}{\":\"}{.status.phase}{\" \"}{end}'" >> "$LOGFILE" 2>&1

# 3. K8s service endpoints
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 user@192.168.1.150 \
    "kubectl get svc -n dining-feedback -o wide" >> "$LOGFILE" 2>&1

# 4. Local nginx on 192.168.1.239
check_http "http://192.168.1.239/" "nginx-frontend" || failed=1
check_http "http://192.168.1.239/api/health" "nginx-api" || failed=1
check_http "http://192.168.1.239/auth/v1/health" "nginx-supabase-auth" || failed=1

# 5. Supabase auth directly
check_http "http://172.22.0.9:9999/health" "supabase-auth" || failed=1

# 6. K8s backend health
backend_ip="192.168.1.190"
check_http "http://${backend_ip}:3000/health" "k8s-backend-direct" || failed=1

log "=== Health check complete. failures=$failed ==="
exit $failed
