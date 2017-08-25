# The name of the DMon cluster
export DMON_CLUSTER_NAME=MyDmonCluster

# Use the private address of the DICE Deployment Service host
export DDS_DNS_SERVER=10.50.51.4

# Configuration for Logstash Forwarder's certificate. Change the C, ST, L, O
# in the following template.
read -r -d '' LSF_OPENSSL_CONF <<EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  C = SL
  ST = Slovenia
  L =  Ljubljana
  O = YourOrgLtd
  CN = *
  [v3_req]
  subjectKeyIdentifier = hash
  authorityKeyIdentifier = keyid,issuer
  basicConstraints = CA:TRUE
  subjectAltName = IP:0.0.0.0
  [v3_ca]
  keyUsage = digitalSignature, keyEncipherment
  subjectAltName = IP:0.0.0.0
EOF
export LSF_OPENSSL_CONF="$LSF_OPENSSL_CONF"