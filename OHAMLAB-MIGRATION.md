# OhamLab Harness — migration candidate

Forked from DeepSeek Harness (MIT); original license and third-party notices retained.

- New assumed GitHub repository: `https://github.com/innokria/ohamlab-harness`, branch `main`. Change deployment build argument and `OHAMLAB_REPO_URL` if different.
- Package scope migrated to `@ohamlab/`; internal `dsh` names and versions retained for compatibility. Do not publish until you control the npm scope.
- Native DeepSeek chat, files and search adapters disabled; session telemetry forced off; hardcoded service URLs replaced with disabled.invalid. Generic model adapter rejects direct DeepSeek domains and model/route names. Historical tests and protocol types remain; tests expecting upstream behavior need updating.
- Branding integrated into shipped brand slots; browser voice input uses on-device recognition only, and selected-text playback uses a local voice only. No cloud fallback. Legacy fish animation and remote voice plugin are not active.
- MCP client and OhamLab search stdio configuration are bundled; Python installer installs ohamlab-agent and agent-lab dependencies. The old third-party UI plugins are no longer automatically installed; agent-lab UI integration is not verified or bundled.
- Fresh installation recommended: old profile manifests, cached node_modules, and saved settings can contain incompatible names and routes. Back up sessions before using a fresh DSH_HOME.
- Build: Node >=22.19, pnpm 11.7.0; `pnpm install --no-frozen-lockfile`, `pnpm run build`, then test the web profile. Docker/Python installer can clone main from the new repository.
- Static checks only; no full build or live network test performed. Network egress allowlisting outside the app is required for a strong privacy guarantee. Third-party models, MCP tools, shell commands and dependencies can still make network requests. Do not use secrets or real conversations until verified.
