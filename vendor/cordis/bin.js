#!/usr/bin/env node

import { Context } from '@ohamlab/cordis'
import { pathToFileURL } from 'node:url'
import Loader from '@ohamlab/cordis-plugin-loader'

const ctx = new Context()
ctx.baseUrl = pathToFileURL(process.cwd()).href + '/'

await ctx.plugin(Loader)
await ctx.loader.create({
  name: '@ohamlab/cordis-plugin-include',
  config: {
    path: './cordis.yml',
  },
})
