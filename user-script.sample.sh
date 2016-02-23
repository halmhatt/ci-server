#!/bin/bash -v

# Make sure that this file exists with a none zero status code
# if tests were unsuccessful. For easiness sake, end with `npm test`

# Install npm modules
npm install

# Run tests
npm test