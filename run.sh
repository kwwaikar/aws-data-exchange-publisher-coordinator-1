#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace

SOLUTION_NAME='aws-data-exchange-publihser-coordinator' # name of the solution
SOLUTION_VERSION='1.0.0' # version number for the source code
SOURCE_CODE_BUCKET='<SOURCE_CODE_BUCKET_NAME>' # existing bucket where source code will reside
MANIFEST_BUCKET='adx-publishing-flow-manifest-test' # new bucket that will be created in this solution
ASSET_BUCKET='adx-publisher-coordinator-assets-bucket-1234' # Existing bucket where new assets are added.
MANIFEST_BUCKET_LOGGING_BUCKET='adx-provider-coordinator-rearc-logging' # Existing bucket where activity logs will be saved.
MANIFEST_BUCKET_LOGGING_PREFIX='adx-publishing-workflow-test-logs/' # Prefix string for manifest bucket access logs (including the trailing slash).
LOGGING_LEVEL='DEBUG' # Logging level of the solution; accepted values: [ DEBUG, INFO, WARNING, ERROR, CRITICAL ]

STACK_NAME='<CLOUDFORMATION_STACK_NAME>' # name of the cloudformation stack
REGION='us-east-1' # region where the cloudformation stack will be created

echo "------------------------------------------------------------------------------"
echo "Custom Variables"
echo "------------------------------------------------------------------------------"
echo "SOLUTION_NAME=$SOLUTION_NAME"
echo "SOLUTION_VERSION=$SOLUTION_VERSION"
echo "SOURCE_CODE_BUCKET=$SOURCE_CODE_BUCKET"
echo "MANIFEST_BUCKET=$MANIFEST_BUCKET"
echo "ASSET_BUCKET=$ASSET_BUCKET"
echo "MANIFEST_BUCKET_LOGGING_BUCKET=$MANIFEST_BUCKET_LOGGING_BUCKET"
echo "MANIFEST_BUCKET_LOGGING_PREFIX=$MANIFEST_BUCKET_LOGGING_PREFIX"
echo "LOGGING_LEVEL=$LOGGING_LEVEL"
echo " "
echo "STACK_NAME=$STACK_NAME"
echo "REGION=$REGION"
echo "------------------------------------------------------------------------------"

echo "mkdir -p local"
rm -rf "local"
echo "rm -rf local"
mkdir -p "local"

echo "------------------------------------------------------------------------------"
echo "package and upload the Lambda code"
echo "------------------------------------------------------------------------------"
cd deployment
chmod +x ./package-and-upload-code.sh
./package-and-upload-code.sh "$SOLUTION_NAME" "$SOLUTION_VERSION" "$SOURCE_CODE_BUCKET"

echo "------------------------------------------------------------------------------"
echo "Use AWS SAM to build and deploy the Cloudformation template"
echo "------------------------------------------------------------------------------"
cd ../source
sam build \
    --parameter-overrides \
        ParameterKey=SolutionName,ParameterValue="$SOLUTION_NAME" \
        ParameterKey=SolutionVersion,ParameterValue="$SOLUTION_VERSION" \
        ParameterKey=SourceCodeBucket,ParameterValue="$SOURCE_CODE_BUCKET" \
        ParameterKey=ManifestBucket,ParameterValue="$MANIFEST_BUCKET" \
        ParameterKey=AssetBucket,ParameterValue="$ASSET_BUCKET" \
        ParameterKey=ManifestBucketLoggingBucket,ParameterValue="$MANIFEST_BUCKET_LOGGING_BUCKET" \
        ParameterKey=ManifestBucketLoggingPrefix,ParameterValue="$MANIFEST_BUCKET_LOGGING_PREFIX" \
        ParameterKey=LoggingLevel,ParameterValue="$LOGGING_LEVEL" 

sam package --s3-bucket "$SOURCE_CODE_BUCKET" \
    --region "$REGION" \
    --output-template-file "../local/$SOLUTION_NAME-SAM.template"

sam deploy --template-file "../local/$SOLUTION_NAME-SAM.template" \
    --parameter-overrides \
        ParameterKey=SolutionName,ParameterValue="$SOLUTION_NAME" \
        ParameterKey=SolutionVersion,ParameterValue="$SOLUTION_VERSION" \
        ParameterKey=SourceCodeBucket,ParameterValue="$SOURCE_CODE_BUCKET" \
        ParameterKey=ManifestBucket,ParameterValue="$MANIFEST_BUCKET" \
        ParameterKey=AssetBucket,ParameterValue="$ASSET_BUCKET" \
        ParameterKey=ManifestBucketLoggingBucket,ParameterValue="$MANIFEST_BUCKET_LOGGING_BUCKET" \
        ParameterKey=ManifestBucketLoggingPrefix,ParameterValue="$MANIFEST_BUCKET_LOGGING_PREFIX" \
        ParameterKey=LoggingLevel,ParameterValue="$LOGGING_LEVEL" \
    --region "$REGION" --stack-name "$STACK_NAME" --capabilities CAPABILITY_IAM
