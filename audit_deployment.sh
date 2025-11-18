#!/bin/bash

NAMESPACE="formazione-sou"
DEPLOYMENT_NAME="flask-app"
SERVICE_ACCOUNT="deployment-monitor"

echo "INIZIO AUDIT: Analisi Deployment '$DEPLOYMENT_NAME'..."

# 1. AUTENTICAZIONE: Genero il Token
echo "Generazione Token per $SERVICE_ACCOUNT..."
TOKEN=$(kubectl create token $SERVICE_ACCOUNT -n $NAMESPACE --duration=10m 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "ERRORE CRITICO: Impossibile generare il token."
    echo "Verifica di aver applicato il file audit-rbac.yaml"
    exit 1
fi

# 2. EXPORT: Scarico l'export dei dati in formato JSON del Deployment
# --token=$TOKEN forzo kubectl a usare l'identità dell'ispettore, non la mia (admin)
echo "Scaricamento dati dal Cluster..."
JSON_DATA=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE --token=$TOKEN -o json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "ACCESSO NEGATO o DEPLOYMENT NON TROVATO."
    echo "Verifica permessi RBAC o che il deploy esista."
    exit 1
fi

# 3. CONTROLLI: Uso jq per cercare i valori mancanti
echo "Verifica Best Practices (Security & Reliability)..."
ERRORS=0

# Definisco il percorso del primo container nel JSON
BASE_PATH=".spec.template.spec.containers[0]"

# Funzione per verificare un campo specifico
check_field() {
    local json_path=$1
    local label=$2
    
    # jq restituisce "null" se il campo non esiste
    VALUE=$(echo "$JSON_DATA" | jq -r "$json_path // empty")
    
    if [ -z "$VALUE" ]; then
        echo "MANCA: $label"
        ERRORS=1
    else
        echo "PRESENTE: $label"
    fi
}

# Eseguiamo i 4 controlli di interesse
check_field "$BASE_PATH.livenessProbe" "Liveness Probe"
check_field "$BASE_PATH.readinessProbe" "Readiness Probe"
check_field "$BASE_PATH.resources.limits" "Resource Limits"
check_field "$BASE_PATH.resources.requests" "Resource Requests"

echo "---------------------------------------------------"

if [ $ERRORS -eq 1 ]; then
    echo "AUDIT FALLITO: Il deployment non è conforme."
    exit 1 
else
    echo "AUDIT SUPERATO: Ottimo lavoro!"
    exit 0
fi
