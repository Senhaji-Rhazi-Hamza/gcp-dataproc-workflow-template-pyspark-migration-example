include .env

build: clean
	mkdir ./dist
	cp ./src/main.py ./dist
	cd ./src && zip -x main.py -r ../dist/jobs.zip .

create_template:
	gcloud dataproc workflow-templates create \
	${TEMPLATE_ID} --region ${REGION}

clean: clean_pyc clean_dist

clean_dist:
	rm -rf dist/ ;

clean_pyc:
	find . -name "*pyc" -exec rm -f {} \;

add_cluster:
	gcloud dataproc workflow-templates set-managed-cluster \
  ${TEMPLATE_ID} \
  --region ${REGION} \
  --zone ${ZONE} \
  --cluster-name three-node-cluster \
  --master-machine-type n1-standard-4 \
  --master-boot-disk-size 500 \
  --worker-machine-type n1-standard-4 \
  --worker-boot-disk-size 500 \
  --num-workers 2 \
  --image-version 1.3-deb9



submit_job:
	gcloud dataproc workflow-templates add-job pyspark  ${BUCKET_NAME}/dist/main.py \
  --step-id ${STEP_ID} \
	--py-files=${BUCKET_NAME}/dist/jobs.zip \
  --workflow-template ${TEMPLATE_ID} \
  --region ${REGION} \
	-- --job=${JOB_NAME} \
		 --job-args="gcs_input_path=${BUCKET_NAME}/data/ibrd-statement-of-loans-historical-data.csv" \
		 --job-args="gcs_output_path=${BUCKET_NAME}/data/ibrd-summary-large-python"

launch_workflow: #build copy_jobs remove_job submit_job 
	time gcloud dataproc workflow-templates \
	instantiate ${TEMPLATE_ID} \
	--region ${REGION}

copy_build:
	gsutil cp ${JOBS_PATH} ${BUCKET_NAME}/dist/jobs.zip
	gsutil cp ${MAIN_PATH} ${BUCKET_NAME}/dist/main.py


export_yaml:
	gcloud dataproc workflow-templates export ${TEMPLATE_ID} \
  --destination workflow_templates/temp.yaml \
  --region ${REGION}

remove_job:
	gcloud dataproc workflow-templates remove-job  ${TEMPLATE_ID}  --region=${REGION} --step-id=${STEP_ID} 

copy_irbd_dataset_2gcp:
	gsutil cp data/ibrd-statement-of-loans-historical-data.csv ${BUCKET_NAME}/data/ibrd-statement-of-loans-historical-data.csv
