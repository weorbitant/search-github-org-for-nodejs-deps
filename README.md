# 🔍 Search GitHub Org for Node.js Dependencies

- [🔍 Search GitHub Org for Node.js Dependencies](#-search-github-org-for-nodejs-dependencies)
  - [⚠️ Context](#️-context)
  - [📋 Prerequisites](#-prerequisites)
  - [🔎 Default Dependencies](#-default-dependencies)
  - [🚀 Usage](#-usage)
  - [💡 Examples](#-examples)
  - [📤 Output](#-output)
  - [📄 License](#-license)

Scan all repositories in a GitHub organization for specific Node.js dependencies.

## ⚠️ Context

This tool was created in response to a [critical security vulnerability in React Server Components](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components) disclosed on December 3, 2025. The vulnerability affects applications using React Server Components with certain bundler integrations.

## 📋 Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) - authenticated
- `jq` - JSON processor
- Optional [`GNU parallel`](https://www.gnu.org/software/parallel/) - run jobs in parallel (great for large organizations) 

## 🔎 Default Dependencies

By default, the script searches for the following dependencies:

- `react-server-dom-parcel`
- `react-server-dom-turbopack`
- `react-server-dom-webpack`
- `next`

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
