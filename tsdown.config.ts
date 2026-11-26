
import { existsSync, globSync } from 'node:fs'
import { join } from 'node:path'
import { defineConfig } from 'tsdown'
import { typertPlugin } from './packages/typert/generator/lib/types/tsdown-plugin.js'

function isBuildFaceClient(value: unknown): boolean {
  if (value === undefined || value === 'host') return false
  if (value === 'client') return true

  throw new Error(
    `tsdown: --env.DSH_BUILD_FACE must be host or client, received ${String(value)}`
  )
}

// Only include actual workspace packages.
const workspacePatterns = [
  'vendor/*',
  'packages/*/*',
  'apps/cli',
]

function resolveWorkspacePackages(): string[] {
  const packages = new Set<string>()

  for (const pattern of workspacePatterns) {
    for (const directory of globSync(pattern)) {
      const manifest = join(directory, 'package.json')

      if (!existsSync(manifest)) {
        console.log(
          `[OHAMLAB BUILD] Skipping non-package directory: ${directory}`
        )
        continue
      }

      packages.add(directory)
    }
  }

  if (packages.size === 0) {
    throw new Error('[OHAMLAB BUILD] No workspace packages found')
  }

  console.log(
    `[OHAMLAB BUILD] Found ${packages.size} workspace packages`
  )

  return [...packages].sort()
}

export default defineConfig(({ env }) => {
  const client = isBuildFaceClient(env?.DSH_BUILD_FACE)

  return {
    workspace: resolveWorkspacePackages(),

    entry: client
      ? ''
      : ['lib/types/{index,invariant,startup}.js'],

    outDir: 'lib',
    format: ['esm'],
    platform: 'node',
    target: 'es2024',
    fixedExtension: false,
    dts: false,
    clean: false,

    plugins: client
      ? []
      : [
          typertPlugin({
            mode: 'workspace',
            faces: ['host'],
          }),
        ],
  }
})
