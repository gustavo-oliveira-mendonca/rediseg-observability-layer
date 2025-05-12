#!/bin/bash -x

BUCKET_PREFIX=rediseg-observability-layers
REGIONS=(
  us-east-1
)

for region in "${REGIONS[@]}"; do
    bucket_name="${BUCKET_PREFIX}-${region}"
    aws s3 mb "s3://${bucket_name}" --region $region
done
