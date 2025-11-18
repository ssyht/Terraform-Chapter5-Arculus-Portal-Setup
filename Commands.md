## Commands to run the main terraform scripts: 

### Running Infrastructure Script:

```bash
cd infrastructure
terraform init
terraform apply -auto-approve
```


### Now run provisioning again

From inside the provision folder:

```bash
terraform init
terraform apply -auto-approve -var="public_ip=<YOUR_PUBLIC_IP>"
```

Example (based on your output):

```bash
terraform apply -auto-approve -var="public_ip=98.81.222.110"
```
