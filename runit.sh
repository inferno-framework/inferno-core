#!/bin/sh

npm install
bundle install
open -a "Google Chrome" http://localhost:4567/
npm run dev
