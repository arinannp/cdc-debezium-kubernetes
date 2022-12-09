# requirement - docker, minikube, kubernetes

kubectl create ns my-kafka-project
kubectl create ns my-postgres-project
kubectl create ns my-beam-project


kubectl create -f strimzi-0.31.1/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n my-kafka-project
kubectl create -f strimzi-0.31.1/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n my-kafka-project

kubectl create -f strimzi-0.31.1/cluster-operator/ -n my-kafka-project

kubectl apply -f kubernetes/kafka-myproject-kafkacluster.yaml
kubectl wait kafka/my-cluster-kafka --for=condition=Ready --timeout=600s -n my-kafka-project


# optional creating a kafka topic for testing purpose
kubectl apply -f kubernetes/kafka-myproject-kafkatopic.yaml
kubectl wait kafkatopic/my-topic-testing --for=condition=Ready --timeout=300s -n my-kafka-project
kubectl run kafka-producer -ti --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --topic my-topic-testing
kubectl run kafka-consumer -ti --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --topic my-topic-testing --from-beginning
kubectl run kafka-topiclist -it --image=strimzi/kafka:0.20.0-rc1-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-topics.sh --bootstrap-server my-cluster-kafka-kafka-bootstrap.my-kafka-project:9092 --list


kubectl apply -f kubernetes/kafka-myproject-kafkaconnect.yaml -n my-kafka-project
kubectl wait kafkaconnect/my-cluster-kafkaconnect-dbz --for=condition=Ready --timeout=300s -n my-kafka-project

kubectl apply -f kubernetes/kafka-myproject-postgres.yaml -n my-postgres-project
kubectl wait deployment/my-postgresdb --for=condition=Available=True --timeout=300s -n my-postgres-project

kubectl apply -f kubernetes/kafka-myproject-debezium.yaml -n my-kafka-project
kubectl wait kafkaconnector/my-connector-dbz --for=condition=Ready --timeout=300s -n my-kafka-project

kubectl apply -f kubernetes/kafka-myproject-pythonkafka.yaml -n my-beam-project
kubectl wait deployment/my-consumerbeam --for=condition=Available=True --timeout=300s -n my-beam-project


# verify that the cdc process works
kubectl get pod -n my-postgres-project
kubectl exec -it $(kubectl get pod -l app=postgresql -n my-postgres-project -o jsonpath="{.items[0].metadata.name}") -n my-postgres-project -- psql -U debezium -d debezium_db

kubectl get pod -n my-beam-project
kubectl exec -it $(kubectl get pod -l app=beam-python -n my-beam-project -o jsonpath="{.items[0].metadata.name}") -n my-beam-project -- /bin/sh
kubectl logs -f $(kubectl get pod -l app=beam-python -n my-beam-project -o jsonpath="{.items[0].metadata.name}") -n my-beam-project
kubectl rollout restart deployment my-consumerbeam -n my-beam-project