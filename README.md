
# Sandbox: Export CloudSQL

Enable
https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview?project=941334562591

Below is copied from [Deployment Manager Samples v2 CloudSQL](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/examples/v2/cloudsql).

> ## Deployment
>
> One can reference the templates schema files for a description of availble options.
>
> **NOTE**: This procedure assumes gcloud is installed
>
> ```sh
> ## Copy example config files.
> $ cp db.example.yaml db.yaml
> $ cp client.example.yaml client.yaml
>
>
> ## Update db.yaml accordingly. See running example below
> $ cat db.yaml
> imports:
>   - path: cloudsql.jinja
>
> resources:
>   - name: cloudsql
>     type: cloudsql.jinja
>     properties:
>       database:
>         name: test
>       dbUser:
>         password: test123_
>       failover: true
>       readReplicas: 1
>
>
> $ gcloud deployment-manager deployments create db01 --config db.yaml
> ...
>
> ## Get Outputs
> $ gcloud deployment-manager manifests describe --deployment db01 | sed -n 's@^.*finalValue: @@p'1
> 35.193.165.42
> go-bears:us-central1:db01-cloudsql-master
> 35.202.14.154
> go-bears:us-central1:db01-cloudsql-failover
> 35.224.104.137
> go-bears:us-central1:db01-cloudsql-rr-0
>
> ## Use the connection string(s) accordingly (See https://cloud.google.com/sql/docs/mysql/sql-proxy](). CloudSQL Proxy > will use this string accordinly.
> $ cat client.yaml
> imports:
>   - path: cloudsql_client.jinja
>   - path: scripts/cloud-sql-proxy.sh
>     name: startup-script
>
> resources:
>   - name: client
>     type: cloudsql_client.jinja
>     properties:
>       cloud-sql-instances: go-bears:us-central1:db01-cloudsql-master
>       clientCount: 2
>
> $ gcloud deployment-manager deployments create client01 --config client.yaml
> ...
>
> ## Ssh into an instance and test mysql
> [mwallman@client01-client-0 ~]$ mysql -uroot -S /var/cloudsql/go-bears\:us-central1\:db01-cloudsql-master -ptest123_ > test
>
> ...
> MySQL [test]>
> ```

## Refs


