#! /usr/bin/env bash

PDS_HOST=${1:-user.eurosky.social}

wsdump "wss://${PDS_HOST}/xrpc/com.atproto.sync.subscribeRepos"