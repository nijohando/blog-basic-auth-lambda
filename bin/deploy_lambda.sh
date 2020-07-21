#!/bin/bash -x

SCRIPT_NAME=$(basename $0)

function usage() {
  echo "usage: ${SCRIPT_NAME} -b <s3 bucket name> -k <s3 key> -f <function name> -o <output json file> <zip archive>"
  echo ""
  exit 1
}

while getopts :b:k:f:o:h OPT
do
  case $OPT in
    b) S3_BUCKET=$OPTARG
      ;;
    k) S3_KEY=$OPTARG
      ;;
    f) LAMBDA_FUNCTION_NAME=$OPTARG
      ;;
    o) OUTPUT_JSON_FILE=$OPTARG
      ;;
    h) usage
      ;;
  esac
done

if [ ! "$S3_BUCKET" ] || [ ! "$S3_KEY" ] || [ ! "$LAMBDA_FUNCTION_NAME" ] || [ ! "$OUTPUT_JSON_FILE" ]
then
  usage
  exit 1
fi

shift $((OPTIND - 1))
ZIP_ARCHIVE=$1

if [ ! -f $ZIP_ARCHIVE ]; then
  echo "File $ZIP_ARCHIVE not found."
  usage
  exit 1
fi

aws s3 cp $ZIP_ARCHIVE s3://${S3_BUCKET}/${S3_KEY}

if [ $? -ne 0 ]; then
  echo "Failed to upload lambda function code."
  exit 1
fi

JSON=$(aws lambda update-function-code \
  --region us-east-1 \
  --function-name $LAMBDA_FUNCTION_NAME \
  --s3-bucket $S3_BUCKET \
  --s3-key $S3_KEY \
  --publish)

if [ $? -ne 0 ]; then
  echo "Failed to publish lambda function."
  exit 1
fi

echo $JSON > $OUTPUT_JSON_FILE
