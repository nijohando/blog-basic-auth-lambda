TMP_DIR := $(shell pwd)/tmp

$(info TMP_DIR: $(TMP_DIR))

.PHONY: clean init build package deploy/lambda deploy/cf test ci_test

clean:
	rm -rf out

init:
	yarn install

build:
	yarn build

package: build
	mkdir -p $(TMP_DIR)
	cd out && zip -r $(TMP_DIR)/lambda.zip ./

deploy/lambda:
	./bin/deploy_lambda.sh -b $(S3_BUCKET) -k $(S3_KEY) -f $(LAMBDA_FUNCTION_NAME) -o $(TMP_DIR)/lambda.json $(TMP_DIR)/lambda.zip

deploy/cf:
	TMP_DIR=$(TMP_DIR) ./bin/deploy_cf.sh -d $(CLOUDFRONT_DISTRIBUTION_ID) $(TMP_DIR)/lambda.json
	

test:
	yarn test

ci_test:
	./bin/codebuild_build.sh -i aws/codebuild/standard:4.0 -c -a tmp -e test.env

