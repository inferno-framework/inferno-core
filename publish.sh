#!/usr/bin/env bash
set -e

npm install
rm -f lib/inferno/public/*bundle.js
npm run build
gem build inferno_core.gemspec
gem push inferno_core*.gem
