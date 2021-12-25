import pulsar

client = pulsar.Client('pulsar://broker3.cluster.test:6650')

consumer = client.subscribe('my-topic', 'test-subscriber')

while True:
    msg = consumer.receive()
    try:
        print("Received message '{}' id='{}'".format(msg.data(), msg.message_id()))
        # Acknowledge successful processing of the message
        consumer.acknowledge(msg)
    except:
        # Message failed to be processed
        consumer.negative_acknowledge(msg)

client.close()
