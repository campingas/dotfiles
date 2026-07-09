# Manage NodeJs


Install mise for Node version management:

```sh
curl https://mise.run | sh
exec zsh
mise use -g node@lts
```

The managed `.zshrc` activates mise automatically after deployment.

Install Bun with the official Bun installer:

```sh
curl -fsSL https://bun.com/install | bash
exec zsh
```

The managed `.zshrc` adds `~/.bun/bin` to `PATH` automatically after deployment.

Enable pnpm through Corepack:

```sh
corepack enable pnpm
```

Verify the Node toolchain:

```sh
node --version
corepack --version
bun --version
pnpm --version
```

## Node package managers

Use Bun by default for your own Node projects:

```sh
bun init
bun install
bun add <package>
bun run <script>
bunx <tool>
```

Use pnpm when a project has `pnpm-lock.yaml`, declares pnpm in `packageManager`, or has a Bun compatibility issue:

```sh
pnpm install
pnpm add <package>
pnpm run <script>
pnpm dlx <tool>
```

For cloned third-party repos, follow the repo lockfile and docs.

- `bun.lock` or `bun.lockb`: use `bun install`
- `pnpm-lock.yaml`: use `pnpm install`
- `package-lock.json`: use `npm install`
- `yarn.lock`: use `corepack yarn install` or the repo's documented Yarn command

Do not replace an upstream repo's lockfile with your preferred package manager.

Update Bun with:

```sh
bun upgrade
```

Update global Node LTS with:

```sh
mise use -g node@lts
```