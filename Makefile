db_stack_name := test-db

create-db:
	gcloud deployment-manager deployments create $(db_stack_name) --config db.yaml

update-db:
	gcloud deployment-manager deployments update $(db_stack_name) --config db.yaml

delete-db:
	gcloud deployment-manager deployments delete $(db_stack_name)
