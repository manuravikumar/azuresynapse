import os, json, time, random, datetime as dt
from azure.eventhub import EventHubProducerClient, EventData

# Usage:
#   pip install azure-eventhub
#   python generate_stream.py
#
# Set via env var or paste connection string below.
CONNECTION_STR = os.getenv("EVENTHUB_CONNECTION_STRING", "<REPLACE_WITH_eventhub_send_connection_string>")
EVENTHUB_NAME  = os.getenv("EVENTHUB_NAME", "<REPLACE_WITH_eventhub_name>")

stores = [f"S{str(i).zfill(3)}" for i in range(1, 11)]
products = [f"P{str(i).zfill(4)}" for i in range(1, 201)]
payment_types = ["card","cash","online"]

def make_event():
    payload = {
        "transaction_id": f"live-{int(time.time()*1000)}",
        "datetime": dt.datetime.utcnow().isoformat(),
        "store_id": random.choice(stores),
        "product_id": random.choice(products),
        "quantity": random.randint(1,5),
        "unit_price": round(random.uniform(1.0, 200.0), 2),
        "payment_type": random.choice(payment_types)
    }
    return EventData(json.dumps(payload))

if __name__ == "__main__":
    if "REPLACE_WITH" in CONNECTION_STR:
        raise SystemExit("Please set EVENTHUB_CONNECTION_STRING and EVENTHUB_NAME first.")
    producer = EventHubProducerClient.from_connection_string(conn_str=CONNECTION_STR, eventhub_name=EVENTHUB_NAME)
    print("Sending events. Ctrl+C to stop.")
    try:
        while True:
            batch = producer.create_batch()
            for _ in range(50):
                batch.add(make_event())
            producer.send_batch(batch)
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopped.")