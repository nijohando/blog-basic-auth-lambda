#!/bin/bash

SCRIPT_NAME=$(basename $0)

function usage() {
  echo "usage: ${SCRIPT_NAME} -d <distribution id> <lambda json file>"
  echo ""
  exit 1
}

while getopts :d:h OPT
do
  case $OPT in
    d) DISTRIBUTION_ID=$OPTARG
      ;;
    h) usage
      ;;
  esac
done

if [ ! "$DISTRIBUTION_ID" ]
then
    usage
    exit 1
fi

shift $((OPTIND - 1))
LAMBDA_JSON_FILE=$1

if [ ! -f $LAMBDA_JSON_FILE ]; then
  echo "File $LAMBDA_JSON_FILE not found"
  usage
  exit 1
fi

LAMBDA_QUALIFIED_ARN=$(cat $LAMBDA_JSON_FILE | jq -r .FunctionArn)
LAMBDA_ARN=${LAMBDA_QUALIFIED_ARN%:*}

GET_DIST_CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID)

if [ $? -ne 0 ]; then
  echo "Failed to get current distribution config."
  exit 1
fi

ETAG=$(echo $GET_DIST_CONFIG | jq -r  .ETag)
DIST_CONFIG=$(echo $GET_DIST_CONFIG | jq -r  .DistributionConfig)

NEW_DIST_CONFIG_JSON=${TMP_DIR}/cf_config_${ETAG}.json

echo $DIST_CONFIG |
  jq \
  --arg LAMBDA_ARN "$LAMBDA_ARN" \
  --arg LAMBDA_QUALIFIED_ARN "$LAMBDA_QUALIFIED_ARN" \
  '.DefaultCacheBehavior.LambdaFunctionAssociations.Items |= map(.LambdaFunctionARN = if (.LambdaFunctionARN | startswith($LAMBDA_ARN)) then $LAMBDA_QUALIFIED_ARN else . end)' \
  > $NEW_DIST_CONFIG_JSON

if [ $? -ne 0 ]; then
  echo "Failed rewrite distribution config."
  exit 1
fi

aws cloudfront update-distribution \
  --id $DISTRIBUTION_ID \
  --distribution-config file://$NEW_DIST_CONFIG_JSON \
  --if-match $ETAG \
  > ${TMP_DIR}/cf_config_${ETAG}_inprogress.json

if [ $? -ne 0 ]; then
  echo "Failed to update distribution config."
  exit 1
fi
