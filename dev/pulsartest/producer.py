import pulsar

client = pulsar.Client('pulsar://broker1.cluster.test:6650')

producer = client.create_producer('my-topic')

while True:
    msg = input()
    producer.send(msg.encode('utf-8'))

client.close()
