#!/bin/bash

HCURL="https://hc-ping.com/your-uuid-here"
WAVELOG_URL="https://example.com/user/login"
OK_CODE=200

curl -m 5 --retry 3 -s $HCURL/start #kick off job

response=$(curl -m 5 --retry 3 -s -w "%{http_code}" $WAVELOG_URL)
http_code=$(tail -n1 <<< "$response")  # get the last line

if [ $http_code -eq $OK_CODE ]
then
        echo "Successfully pinged Wavelog."
        curl -m 5 --retry 3 -s $HCURL
else
        echo "Ping failed, got status code $http_code"
        curl -fsS -m 5 --retry 3 --data-raw "Status Code: $http_code" -s "$HCURL/fail"
fi
