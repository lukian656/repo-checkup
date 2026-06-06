# repo-checkup

A small GitHub starter kit and repository health checker for keeping projects clean before commits, pushes, and pull requests.

## Features

- Repository health report script for PowerShell
- Checks for important project files
- Detects large files before they accidentally reach GitHub
- Looks for obvious secret patterns
- Finds TODO, FIXME, and HACK markers
- Includes contribution, issue, and pull request templates

## Getting Started

### Prerequisites

- Windows PowerShell or PowerShell 7+
- Git, optional but recommended

### Installation

```bash
git clone https://github.com/lukian656/repo-checkup.git
cd repo-checkup
```

## Usage

Run a repository health check:

```powershell
powershell -ExecutionPolicy Bypass -File .\repo-health.ps1 -Path .
```

Generate a Markdown report that can be pasted into a GitHub issue or pull request:

```powershell
powershell -ExecutionPolicy Bypass -File .\repo-health.ps1 -Path . -Markdown
```

Change the large-file warning threshold:

```powershell
powershell -ExecutionPolicy Bypass -File .\repo-health.ps1 -Path . -LargeFileMb 25
```

## What It Checks

- `README.md`
- `.gitignore`
- `CONTRIBUTING.md`
- `LICENSE`
- Issue templates
- Pull request template
- Common test directories
- Large files
- Obvious secret-like values
- TODO, FIXME, and HACK markers
- Git working tree status

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MIT
