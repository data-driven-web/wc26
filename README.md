# WC26 Project

This repository contains the full WordPress setup for WC26 with a clean, modular architecture for core functionality, feature plugins, theme presentation, and deployment operations.

## 📂 Repository Layout

```text
/wp-content/
  /plugins/
    wc26-core/           # Core CPTs, REST endpoints, JSON-LD (code-reviewed via PR)
    wc26-predictor/      # Feature plugin
    wc26-schedule/       # Feature plugin
    wc26-lineup/         # Feature plugin
  /mu-plugins/
    wc26-hardening.php   # Env flags, headers, auth/REST hardening

/theme/
  your-child-theme/      # Presentation layer (patterns, templates, styles)

/ops/
  restore_wc2026.sh      # Restoration script
  post_deploy.sh         # Cache + rewrite flush, health checks
  drift_check.sh         # Compares plugin/theme versions vs lock

wp-cli.yml               # CLI aliases for staging/prod
