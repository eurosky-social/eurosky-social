locals {
  pds_hostname     = "pds.${var.cluster_domain}"
  pds_public_url   = "https://${local.pds_hostname}"
  pds_version      = "0.4.0"
  pds_storage_size = "10Gi"
}

resource "kubernetes_namespace" "pds" {
  metadata {
    name = "pds"
  }
}

resource "kubectl_manifest" "pds_storageclass" {
  yaml_body = templatefile("${path.module}/pds-storageclass.yaml", {
    storage_provisioner = var.pds_storage_provisioner
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_configmap_litestream" {
  yaml_body = templatefile("${path.module}/pds-configmap-litestream.yaml", {
    namespace       = kubernetes_namespace.pds.metadata[0].name
    backup_bucket   = var.backup_s3_bucket
    backup_region   = var.backup_s3_region
    backup_endpoint = var.backup_s3_endpoint
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_configmap" {
  yaml_body = templatefile("${path.module}/pds-configmap.yaml", {
    namespace              = kubernetes_namespace.pds.metadata[0].name
    pds_hostname           = local.pds_hostname
    pds_blobstore_bucket   = var.pds_blobstore_bucket
    pds_blobstore_region   = var.backup_s3_region
    pds_blobstore_endpoint = var.backup_s3_endpoint
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret" {
  yaml_body = templatefile("${path.module}/pds-secret.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    pds_jwt_secret           = var.pds_jwt_secret
    pds_admin_password       = var.pds_admin_password
    pds_plc_rotation_key     = var.pds_plc_rotation_key
    pds_blobstore_access_key = var.pds_blobstore_access_key
    pds_blobstore_secret_key = var.pds_blobstore_secret_key
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_secret_litestream" {
  yaml_body = templatefile("${path.module}/pds-secret-litestream.yaml", {
    namespace                = kubernetes_namespace.pds.metadata[0].name
    backup_access_key_id     = var.backup_s3_access_key
    backup_secret_access_key = var.backup_s3_secret_key
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_service_headless" {
  yaml_body = templatefile("${path.module}/pds-service-headless.yaml", {
    namespace = kubernetes_namespace.pds.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_service" {
  yaml_body = templatefile("${path.module}/pds-service.yaml", {
    namespace = kubernetes_namespace.pds.metadata[0].name
  })

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "pds_ingress" {
  yaml_body = templatefile("${path.module}/pds-ingress.yaml", {
    namespace      = kubernetes_namespace.pds.metadata[0].name
    pds_hostname   = local.pds_hostname
    cluster_domain = var.cluster_domain
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    null_resource.wait_for_nginx_webhook
  ]
}

resource "kubectl_manifest" "pds_statefulset" {
  yaml_body = templatefile("${path.module}/pds-statefulset.yaml", {
    namespace        = kubernetes_namespace.pds.metadata[0].name
    pds_version      = local.pds_version
    pds_storage_size = local.pds_storage_size
    backup_bucket    = var.backup_s3_bucket
    backup_endpoint  = var.backup_s3_endpoint
    backup_region    = var.backup_s3_region
  })

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.pds_storageclass,
    kubectl_manifest.pds_configmap,
    kubectl_manifest.pds_secret,
    kubectl_manifest.pds_secret_litestream,
    kubectl_manifest.pds_configmap_litestream
  ]
}

# TODO: Increase storage_size production workloads
# TODO: Evaluate actual storage needs based on user count
# TODO: Create environment-specific overlays (dev vs. prod)
# TODO: Add depends_on for cert-manager and nginx-ingress to ensure infrastructure is ready before PDS deployment
# TODO: Add lifecycle.prevent_destroy for production PVC to prevent accidental data loss
# TODO: Production should use 100Gi+ storage, current 10Gi is dev sizing
# TODO: Add local.pds_email_smtp_url for email verification (recommended per official docs)
# TODO: Add local.pds_email_from_address for email verification (recommended per official docs)
# TODO: Add labels for better resource organization (app.kubernetes.io/name, app.kubernetes.io/managed-by)
# TODO: Add depends_on for CSI driver if using cloud-specific storage provisioner
# TODO: Add pds_email_smtp_url for email verification (PDS_EMAIL_SMTP_URL per official docs)
# TODO: Add pds_email_from_address for email verification (PDS_EMAIL_FROM_ADDRESS per official docs)
# TODO: Add pds_repo_signing_key variable (PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX - CRITICAL REQUIRED per official docs)
# TODO: Add pds_recovery_did_key variable (PDS_RECOVERY_DID_KEY - CRITICAL REQUIRED per official docs)
# TODO: Add explicit dependencies for secrets and configmaps to ensure proper creation order
# TODO: Add missing required secrets (PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX, PDS_RECOVERY_DID_KEY)
# TODO: Add email verification support (PDS_EMAIL_SMTP_URL, PDS_EMAIL_FROM_ADDRESS)
# TODO: Add monitoring/observability integration (Prometheus metrics, Grafana dashboards)
# TODO: Add resource quotas and limits at namespace level per GUIDELINES.md
# TODO: Add NetworkPolicy for pod-to-pod security per GUIDELINES.md
# TODO: Add PodDisruptionBudget (note: single replica limitation means PDB will be minAvailable=0)
# TODO: Implement environment-specific tfvars (dev.tfvars, prod.tfvars)
# TODO: Add output values for PDS endpoint and health check URL
