include .env
include make/help.Makefile

ROOTH_PATH:=$(shell pwd)

build: clean ## build dist without dependencies
	mkdir ./dist
	cp ./src/main.py ./dist
	cd ./src && zip -x main.py -r ../dist/jobs.zip .

build_with_deps: clean ##build dist with dependencies
	cp ./src/main.py ./dist
	cd ./src && zip -x main.py -x \*libs\* -r ../dist/jobs.zip .
	cd ./src/libs && zip -r ../../dist/libs.zip .


create_template: ## create DWT template
	gcloud dataproc workflow-templates create \
	${TEMPLATE_ID} --region ${REGION}


delete_template: ## delete DWT template
	gcloud dataproc workflow-templates delete \
	${TEMPLATE_ID} --region ${REGION}

clean: clean_pyc clean_dist clean_dep_requirements

clean_dist: ## delete dist folder
	rm -rf dist/ ;


clean_dep_requirements: ## delete libs folder
	find . -name libs | xargs rm -rf \;

clean_pyc: ## delete pyc python files
	find . -name "*pyc" -exec rm -f {} \;

add_cluster: ## add a cluster config to DWT
	gcloud dataproc workflow-templates set-managed-cluster \
  ${TEMPLATE_ID} \
  --region ${REGION} \
  --zone ${ZONE} \
  --cluster-name three-node-cluster \
  --master-machine-type n1-standard-2 \
  --master-boot-disk-size 500 \
  --worker-machine-type n1-standard-2 \
  --worker-boot-disk-size 500 \
  --num-workers 2 \
  --image-version 1.3-deb9



submit_job: ## submit a job config to a DWT
	gcloud dataproc workflow-templates add-job pyspark  ${BUCKET_NAME}/dist/main.py \
  --step-id ${STEP_ID} \
	--py-files=${BUCKET_NAME}/dist/jobs.zip \
  --workflow-template ${TEMPLATE_ID} \
  --region ${REGION} \
	-- --job=${JOB_NAME} \
		 --job-args="gcs_input_path=${BUCKET_NAME}/data/ibrd-statement-of-loans-historical-data.csv" \
		 --job-args="gcs_output_path=${BUCKET_NAME}/data/ibrd-summary-large-python"

launch_workflow: ## triger the run for our DWT
	time gcloud dataproc workflow-templates \
	instantiate ${TEMPLATE_ID} \
	--region ${REGION}


copy_build: ## copy build to GCP
	gsutil cp -r ${ROOTH_PATH}/dist ${BUCKET_NAME}


export_yaml: ## export the DWT in a yaml format
	gcloud dataproc workflow-templates export ${TEMPLATE_ID} \
  --destination workflow_templates/temp.yaml \
  --region ${REGION}

remove_job: ## delete the job added fom DWT
	gcloud dataproc workflow-templates remove-job  ${TEMPLATE_ID}  --region=${REGION} --step-id=${STEP_ID} 

copy_irbd_dataset_2gcp: ## unzip and copy irbd dataset to GCP 
	cd  ${ROOTH_PATH}/data && unzip irbd_data.zip;\
	gsutil cp ${ROOTH_PATH}/data/ibrd-statement-of-loans-historical-data.csv ${BUCKET_NAME}/data/ibrd-statement-of-loans-historical-data.csv
