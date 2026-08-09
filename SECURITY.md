# Security Policy

Este proyecto provisiona infraestructura AWS con **modelo Zero-Trust**. La seguridad se aplica en el código y en el proceso. Si encontrás una vulnerabilidad, reportala de forma responsable.

## Reporting a Vulnerability

**NO abras un issue público con detalles de la vulnerabilidad.**

Envía el reporte a <ori_amontani@niubiz.com.pe> (o al owner del repo en GitHub) con:

- Resumen del problema y riego potencial
- Reproducción (si aplica)
- Impacto esperado si se explota
- Sugerencias de mitigación (si las tenés)

Compromiso:

- Confirmación de recepción en **48 h hábiles**
- Actualización del estado dentro de **7 días**
- Coordinación de divulgación con el reporter antes de cualquier publicación

## Alcance

- `terraform/**` — IaC (KMS, VPC, EKS, IAM/Pod Identity)
- `k8s/**` — NetworkPolicies, Kyverno, External Secrets
- `.github/workflows/**` — supply-chain del CI

## Postura de seguridad del proyecto

| Control | Estado |
|---|---|
| EKS endpoint público | deshabilitado (`endpoint_public_access=false`) |
| Secrets del control-plane | cifrados con CMK dedicado KMS |
| EBS nodos | `encrypted=true` + `kms_key_id` |
| VPC Flow Logs | habilitados, cifrados con KMS |
| IMDSv2 | `required` (prohibido IMDSv1) |
| Identidad de workloads | EKS Pod Identity (rol IAM por servicio) |
| NetworkPolicies | deny-by-default (Ingress + Egress) |
| Kyverno | enforce: non-root, no-privileged, readOnlyRootFS, limits, seccomp |
| Secrets en el repo | nunca habilitados; via External Secrets ← Secrets Manager |

## Best practices para contribuir

1. **Nunca** commits de `*.tfstate`, `*.tfvars`, `.env` ni credenciales.
2. GitHub Actions con `permissions` mínimas y acciones pineadas a SHA.
3. Añadir/actualizar la entrada en `terraform/.checkov.yaml` solo con justificación documentada.
4. Verificar localmente: `terraform fmt -check -recursive`, `terraform validate` y `tflint` antes del PR.

## Dependencias

Las dependencias (GitHub Actions y providers de Terraform) se actualizan automáticamente vía **Dependabot** quincenal. Mantené las actualizaciones de seguridad con prioridad.