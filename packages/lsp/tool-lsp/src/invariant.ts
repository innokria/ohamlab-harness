/**
 * Package-owned invariant companion for `@ohamlab/dsh-tool-lsp`.
 * @module @ohamlab/dsh-tool-lsp/invariant
 */

/* jscpd:ignore-start */
import type { Context } from '@ohamlab/cordis'
import type { InvariantInstaller } from '@ohamlab/dsh-invariants'

const PACKAGE_NAME = '@ohamlab/dsh-tool-lsp'

/** Cordis companion plugin name. */
export const name = 'tool-lsp-invariant'
/** Service required before the companion can reserve package ownership. */
export const inject = ['invariants']

/**
 * No runtime invariant: this stateless adapter contributes one tool and prompt section, while query
 * lifecycle and result relations remain owned by the tool and LSP seams it composes.
 */
const install: InvariantInstaller = () => {}

/**
 * Register this package's invariant companion.
 * @param ctx - Cordis context carrying the invariant service.
 * @returns the installed registration's disposer after setup succeeds.
 */
export const apply = (ctx: Context): Promise<() => void> =>
  Promise.resolve(ctx.invariants.register(PACKAGE_NAME, install))
/* jscpd:ignore-end */
