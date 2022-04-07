#!/usr/bin/env bash
set -e

npm run build
gem build inferno_core.gemspec
gem push inferno_core*.gem
