db_stack_name := test-db

create-db:
	gcloud deployment-manager deployments create $(db_stack_name) --config db.yaml

update-db:
	gcloud deployment-manager deployments update $(db_stack_name) --config db.yaml

delete-db:
	gcloud deployment-manager deployments delete $(db_stack_name)

connect-db:
	docker run -it --rm -v $(PWD):/app -w /app postgres \
		psql "sslmode=verify-ca sslrootcert=server-ca.pem \
			sslcert=client-cert.pem sslkey=client-key.pem \
			hostaddr=$(host) \
			port=5432 \
			user=root dbname=test"
