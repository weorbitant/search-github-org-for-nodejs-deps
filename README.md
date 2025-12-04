# 🔍 Search GitHub Org for Node.js Dependencies

- [🔍 Search GitHub Org for Node.js Dependencies](#-search-github-org-for-nodejs-dependencies)
  - [📋 Prerequisites](#-prerequisites)
  - [🚀 Usage](#-usage)
  - [💡 Examples](#-examples)
  - [📤 Output](#-output)
  - [📄 License](#-license)

Scan all repositories in a GitHub organization for specific Node.js dependencies.

## 📋 Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) - authenticated
- `jq` - JSON processor

## 🚀 Usage

```bash
./check-repositories-for-node-deps.sh <organization-name> [dependencies]
```

## 💡 Examples

```bash
# Using default dependencies (react-server-dom-*)
./check-repositories-for-node-deps.sh my-org

# Custom dependencies (comma-separated)
./check-repositories-for-node-deps.sh my-org "lodash,express,axios"
```

## 📤 Output

- Downloads all `package.json` files to `./repos_with_package_json/`
- Shows ⚠️ warnings for each found dependency
- Displays version and dependency type (dependencies, devDependencies, peerDependencies)

## 📄 License

MIT
See [LICENSE](LICENSE) for more information.

Made with ❤️ by @GentooXativa
