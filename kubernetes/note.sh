"""
Be aware that deploying Cluster Operator requires a Kubernetes user account that has permission to create:
CustomResourceDefinitions, ClusterRoles and ClusterRoleBindings.
"""
kubectl create clusterrolebinding strimzi-cluster-operator-namespaced --clusterrole=strimzi-cluster-operator-namespaced --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-entity-operator-delegation --clusterrole=strimzi-entity-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-topic-operator-delegation --clusterrole=strimzi-topic-operator --serviceaccount kafka:strimzi-cluster-operator


kubectl run kafka-producer -ti --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --topic my-topic
kubectl run kafka-consumer -ti --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --topic my-topic --from-beginning
kubectl run kafka-topiclist -it --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --list



INSERT INTO person_identity (login_date, first_name, last_name, address, active) VALUES ('2022-12-09', 'Arinan', 'Najah', 'Semarang, IND', true);
UPDATE person_identity SET active=false WHERE id=1;

Changes Data Capture
PostgreSQL -> Debezium -> Kafka

kubectl create ns kafka
kubectl create ns my-kafka-project

kubectl apply -f kafka-myproject-kafkacluster.yaml -n my-kafka-project
kubectl apply -f kafka-myproject-kafkatopic.yaml -n my-kafka-project

kubectl create secret docker-registry mydockercred --docker-server=https://index.docker.io/v1/ --docker-username=arinannp --docker-password=paridenajah --docker-email=arinannp@gmail.com -n my-kafka-project

Windows Powershell => Get-FileHash file-name.tar.gz -Algorithm SHA512 | Format-List
Windows Powershell => Get-FileHash file-name.jar -Algorithm SHA512 | Format-List

kubectl apply -f kafka-myproject-kafkaconnect.yaml -n my-kafka-project

kubectl create ns my-postgres-project
# kubectl create configmap sql-command --from-file=initdb.sql -n my-postgres-project

docker build -t arinannp/postgres-13:latest Postgres/.
docker push arinannp/postgres-13:latest
kubectl apply -f kafka-myproject-postgres.yaml -n my-postgres-project

kubectl get pod -n my-postgres-project
kubectl exec -it my-postgresdb-yourgeneratedpod -n my-postgres-project -- psql -U debezium -d debezium_db

kubectl apply -f kafka-myproject-debezium.yaml -n my-kafka-project
kubectl get kafkatopic -A

docker build -t arinannp/python-kafka-consumer:latest Python/.
docker push arinannp/python-kafka-consumer:latest
kubectl apply -f kafka-myproject-pythonkafka.yaml -n my-beam-project