
# CloudSQL import/export (Setup with Deployment Manager)

Enable
https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview?project=941334562591

Originally copied from [Deployment Manager Samples v2 CloudSQL](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/examples/v2/cloudsql).

## Usage

Deploy a DB server, create a DB and a user.

```sh
make create-db db_stack_name=foobar
```

Go to the SQL admin console and create a client key, cert and ca cert.

Login as the DB user.

```sh
make connect-db host='host-ip'
```
