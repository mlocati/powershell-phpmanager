## Maintainers instructions

### Publishing a new version

In order to publish a new version (both on [PowerShell Gallery](https://www.powershellgallery.com/packages/PhpManager) and on [GitHub Releases](https://github.com/mlocati/powershell-phpmanager/releases)), simply push a tag in the following form:
`<major version>.<minor version>.<patch version>`

The release notes will be built automatically, extracting the subject (that is, the first line) from every commit that touches the `PhpManager` directory, provided that they don't start with `[minor]`.
