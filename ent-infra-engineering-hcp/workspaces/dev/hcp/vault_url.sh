#!/bin/bash

if curl -Li --output /dev/null --silent --head --fail $1 ; then
  echo "::set-output name=url::true"
else
  echo "URL Endpoint Unreachable"
fi
