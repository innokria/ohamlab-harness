import { clientBundle } from '../tsdown.client.ts'

export default clientBundle(
  '@ohamlab/dsh-client-modules',
  ['lib/types/index.js', 'lib/types/invariant.js'],
)
