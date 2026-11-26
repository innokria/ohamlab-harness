/**
 * Package-owned invariant companion for `@ohamlab/dsh-session-query`.
 * @module @ohamlab/dsh-session-query/invariant
 */

/* jscpd:ignore-start */
import type { Context } from '@ohamlab/cordis'
import type { InvariantInstaller } from '@ohamlab/dsh-invariants'

const PACKAGE_NAME = '@ohamlab/dsh-session-query'

/** Cordis companion plugin name. */
export const name = 'session-query-invariant'
/** Service required before the companion can reserve package ownership. */
export const inject = ['invariants']

/**
 * No runtime invariant: query results are immutable per-call projections whose lineage and event
 * relations are validated while they are built; the service retains no observable result state.
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
