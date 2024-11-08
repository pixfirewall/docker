#!/bin/bash

# CA Certificate Generation Script
# Author: Your Name
# Version: 1.0

# Error handling function
error_exit() {
    echo "ERROR: ${1:-"Unknown Error"}" >&2
    exit 1
}

# Configuration Variables (Customize these)
CA_NAME="MyCustomCA"
VALIDITY_DAYS=3650  # 10 years
KEY_STRENGTH=4096

# Directories
CA_DIR="."
BACKUP_DIR="${CA_DIR}/backup"

# Logging
LOG_FILE="${CA_DIR}/ca_generation.log"

# Ensure required tools are installed
command -v openssl >/dev/null 2>&1 || error_exit "OpenSSL is not installed"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Generate CA Configuration
generate_ca_config() {
    local config_file="${CA_DIR}/ca.cnf"
    
    cat > "${config_file}" << EOF
[req]
default_bits = ${KEY_STRENGTH}
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_ca

[dn]
C = US
ST = California
L = San Francisco
O = ${CA_NAME}
OU = Certificate Authority
CN = ${CA_NAME} Root Certificate

[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

    log "CA Configuration file generated: ${config_file}"
}

# Backup existing files if they exist
backup_existing_files() {
    # Create necessary directories
    mkdir -p "${CA_DIR}" "${BACKUP_DIR}" || error_exit "Cannot create directories"
    
    local existing_key="${CA_DIR}/ca.key"
    local existing_cert="${CA_DIR}/ca.pem"
    
    if [[ -f "${existing_key}" ]]; then
        cp "${existing_key}" "${BACKUP_DIR}/ca.key.$(date +'%Y%m%d_%H%M%S')"
        log "Backed up existing key"
    fi
    
    if [[ -f "${existing_cert}" ]]; then
        cp "${existing_cert}" "${BACKUP_DIR}/ca.pem.$(date +'%Y%m%d_%H%M%S')"
        log "Backed up existing certificate"
    fi
}

# Generate CA Key
generate_ca_key() {
    local key_path="${CA_DIR}/ca.key"
    
    openssl genrsa \
        -out "${key_path}" \
        "${KEY_STRENGTH}" || error_exit "Failed to generate CA key"
    
    chmod 400 "${key_path}"
    log "CA Private Key generated: ${key_path}"
}

# Generate CA Certificate
generate_ca_certificate() {
    local key_path="${CA_DIR}/ca.key"
    local cert_path="${CA_DIR}/ca.pem"
    local config_path="${CA_DIR}/ca.cnf"
    
    openssl req \
        -x509 \
        -new \
        -nodes \
        -key "${key_path}" \
        -sha256 \
        -days "${VALIDITY_DAYS}" \
        -out "${cert_path}" \
        -config "${config_path}" || error_exit "Failed to generate CA certificate"
    
    chmod 644 "${cert_path}"
    log "CA Certificate generated: ${cert_path}"
}

# Verify generated files
verify_files() {
    local key_path="${CA_DIR}/ca.key"
    local cert_path="${CA_DIR}/ca.pem"
    
    # Verify private key
    openssl rsa -in "${key_path}" -check >/dev/null 2>&1 || 
        error_exit "Invalid CA Private Key"
    
    # Verify certificate
    openssl x509 -in "${cert_path}" -text -noout >/dev/null 2>&1 || 
        error_exit "Invalid CA Certificate"
    
    log "Files verification successful"
}

# Main execution
main() {
    log "Starting CA Certificate Generation Process"
    
    # backup_existing_files
    generate_ca_config
    generate_ca_key
    generate_ca_certificate
    # verify_files
    
    log "CA Certificate and Key Generation Completed Successfully"
    
    # Display certificate details
    # openssl x509 -in "${CA_DIR}/ca.pem" -text -noout
}

# Execute main function
main

# Exit successfully
exit 0
