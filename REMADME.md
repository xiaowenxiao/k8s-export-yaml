# k8s-export-yaml

A convenient CLI tool for exporting all Kubernetes resources configurations from a namespace to YAML files.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## ✨ Features

- 🚀 One-click export of all K8s resources in a namespace
- 🎯 Supported resource types:
  - Deployments
  - Services
  - Ingresses
  - ConfigMaps
  - Secrets
  - PersistentVolumes
  - PersistentVolumeClaims
  - StorageClasses
  - DaemonSets
  - StatefulSets
  - Jobs
- 🧹 Auto cleanup of runtime data in YAML (uid, resourceVersion, etc.)
- 📊 Resource export statistics
- 🔍 Dry-run mode support for preview

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- `kubectl` - Kubernetes command-line tool
- `yq` (v4.x) - YAML processor
- `bash` 4.0+

## 🚀 Installation
```bash
git clone https://github.com/xiaowenxiao/k8s-export-yaml.git
cd k8s-export-yaml
chmod +x install.sh
./install.sh
```

## 📖 Usage

### Basic Usage

```bash
k8s-export-yaml -n your-namespace
```

### Options

```bash
k8s-export-yaml [-n namespace] [-o output-dir] [--dry-run]

Options:
  -n, --namespace    Target Kubernetes namespace (required)
  -o, --output       Output directory for YAML files (default: ./<namespace>)
  --dry-run          Preview mode without actual export
```

### Examples

Export all resources from the 'production' namespace:
```bash
k8s-export-yaml -n production
```

Export to a specific directory:
```bash
k8s-export-yaml -n production -o /path/to/output
```

Preview export without actual execution:
```bash
k8s-export-yaml -n production --dry-run
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) - The Kubernetes command-line tool
- [yq](https://github.com/mikefarah/yq) - YAML processor

## 📧 Contact

If you have any questions, feel free to reach out:

- Create an issue
- Submit a pull request
- Star this repository if you find it helpful!

---
Made with ❤️ for the Kubernetes community
