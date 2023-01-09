# requirement - docker, minikube, kubernetes

kubectl create ns my-kafka-project
kubectl create ns my-postgres-project
kubectl create ns my-beam-project
kubectl create ns my-prometheus-grafana-project


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


# deploy prometheus-operator and prometheus
kubectl create -f prometheus-0.31.1/prometheus-myproject-operator.yaml -n my-prometheus-grafana-project

# kubectl create secret generic additional-scrape-configs --from-file=prometheus-0.31.1/prometheus-additional-properties/prometheus-additional.yaml -n my-prometheus-grafana-project
kubectl apply -f prometheus-0.31.1/prometheus-additional-properties/prometheus-additional.yaml -n my-prometheus-grafana-project
kubectl apply -f prometheus-0.31.1/prometheus-alertmanager-config/alert-manager-config.yaml -n my-prometheus-grafana-project

kubectl apply -f prometheus-0.31.1/prometheus-install/alert-manager.yaml -n my-prometheus-grafana-project
kubectl apply -f prometheus-0.31.1/prometheus-install/strimzi-pod-monitor.yaml -n my-prometheus-grafana-project
kubectl apply -f prometheus-0.31.1/prometheus-install/prometheus-rules.yaml -n my-prometheus-grafana-project
kubectl apply -f prometheus-0.31.1/prometheus-install/prometheus.yaml -n my-prometheus-grafana-project

kubectl get pods -n my-prometheus-grafana-project
kubectl get svc -n my-prometheus-grafana-project


# deploy grafana (https://strimzi.io/docs/operators/latest/deploying.html#assembly-metrics-setup-str:~:text=Alertmanager%20are%20deployed-,Procedure,-Deploy%20Grafana.)
kubectl apply -f grafana-0.31.1/grafana-install/grafana.yaml -n my-prometheus-grafana-project

kubectl get pods -n my-prometheus-grafana-project
kubectl get svc -n my-prometheus-grafana-project

kubectl port-forward svc/grafana 3000:3000 -n my-prometheus-grafana-project

# Open grafana webpage on web browser
# http://localhost:3000
# username: admin
# password: admin


# add prometheus service address as a data-source inside setting tap (setting -> data source -> add data source)
# http://prometheus-operator:8080                                                     (if same namspace with prometheus)
# http://prometheus-operator.my-prometheus-grafana-project:8080                       (if different namspace with prometheus)
# http://prometheus-operator.my-prometheus-grafana-project.svc.cluster.local:8080     (if different namspace with prometheus, fully qualified name)

# http://prometheus-operated:9090
# http://prometheus-operated.my-prometheus-grafana-project:9090
# http://prometheus-operated.my-prometheus-grafana-project.svc.cluster.local:9090

# import these files to grafana webpage
# grafana-0.31.1/grafana-dashboards/strimzi-kafka.json
# grafana-0.31.1/grafana-dashboards/strimzi-kafka-exporter.json
# grafana-0.31.1/grafana-dashboards/strimzi-operators.json
# grafana-0.31.1/grafana-dashboards/strimzi-zookeeper.json