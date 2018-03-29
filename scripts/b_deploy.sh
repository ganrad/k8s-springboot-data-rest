echo "Creating a new project => myproject ...."
oc new-project myproject --description="Springboot project" --display-name="Springboot test project"

echo "Switching projects to => myproject ...."
oc project myproject

echo "Deploying MySQL (ephemeral) v5.7...."
oc new-app --template=mysql-ephemeral MYSQL_USER=mysql MYSQL_PASSWORD=password MYSQL_ROOT_PASSWORD=password
echo "Waiting 10 seconds for mysql pod to come up ...."
sleep 10

echo "Creating ConfigMap - mysql-db-name ...." 
oc create configmap mysql-db-name --from-file=../mysqldb.properties
echo "List the content of mysql-db-name in project ...."
oc get configmaps mysql-db-name -o yaml
sleep 5

echo "Creating the Secret - mysql-secret ...."
oc create -f ../mysql-secret.yaml
echo "List the content of mysql-secret in project ...."
oc describe secret mysql-secret
sleep 5

echo "Adding mysql-secret to the default service account ...."
oc secrets add serviceaccount/default secret/mysql-secret --for=mount

echo "Creating new build (binary) for po-service application ...."
oc new-build --binary=true --name=po-service --image-stream=redhat-openjdk18-openshift

echo "Starting the build ...."
oc start-build po-service --from-dir=../test --follow

echo "Creating the po-service application ...."
oc new-app po-service

echo "Mounting the MySql server dbname as a configmap into the po-service pod ...."
oc volume dc/po-service --add --name=mysqlcm --type=configmap --configmap-name='mysql-db-name' --mount-path='/etc/vol-secrets'

echo "Mounting the MySql server username and password as secrets into the po-service pod ...."
oc volume dc/po-service --add --name=mysqlse --type=secret --secret-name='mysql-secret' --mount-path='/etc/vol-secrets'

echo "Exposing route for po-service application ...."
oc expose svc/po-service

echo "DONE."
