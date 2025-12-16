# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- HA Control Plane (3 masters)
- ArgoCD for GitOps
- Prometheus + Grafana monitoring stack
- Cert-manager for TLS automation
- Longhorn distributed storage
- Velero for backup and restore

## [1.0.0] - 2025-01-XX

### Added
- Initial project setup
- Terraform configuration for Proxmox VM provisioning
- Ansible roles for system configuration and K3s installation
- K3s cluster deployment (1 master + 2 workers)
- Traefik Ingress Controller
- Kubernetes Dashboard
- Sample applications (Whoami, Uptime Kuma)
- Makefile for orchestration
- Comprehensive documentation
- GitHub Actions for CI/CD
- Utility scripts for management

### Features
- One-command deployment (`make up`)
- Automated VM creation on Proxmox
- Automated K3s installation and configuration
- NodePort access to services
- Local path storage provisioning
- Full teardown capability (`make down`)

### Documentation
- README with quick start guide
- Architecture documentation
- Troubleshooting guide
- Inline code comments
