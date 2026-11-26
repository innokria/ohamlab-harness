/**
 * Package-owned invariant companion for `@ohamlab/dsh-client-ui-settings-general`.
 * @module @ohamlab/dsh-client-ui-settings-general/invariant
 */

/* jscpd:ignore-start */
import type { Context } from '@ohamlab/cordis'
import type { InvariantInstaller } from '@ohamlab/dsh-invariants'

const PACKAGE_NAME = '@ohamlab/dsh-client-ui-settings-general'

/** Cordis companion plugin name. */
export const name = 'client-ui-settings-general-invariant'
/** Service required before the companion can reserve package ownership. */
export const inject = ['invariants']

/**
 * No runtime invariant: the settings seam validates and publishes the durable
 * onboarding section, while slot conflicts fail loud in the slot core. The local
 * document action is browser state over typed RPC responses and is covered by
 * store/component tests rather than a Cordis runtime relationship.
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
