# Copy DB from prod
If you want to fast and easy copy product data from prodaction servers to developers envairoment use this util.

You have 

```shell
ssh <username>@<hostname>
```

for this purpose you have to add the ssh key to target server.

```shell
$ gem install copy_db_from_prod
$ cd rails_root
$ copy_db_from_prod -h bisu4.insales.ru -u deploy --schema-only
```
