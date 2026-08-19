import os
import json
import random
import uuid
import time
from datetime import datetime, timedelta
from dotenv import load_dotenv
from kafka import KafkaProducer

# Load environment variables from the .env file
load_dotenv()

EVENTHUBS_NAMESPACE = os.getenv("EVENTHUBS_NAMESPACE")
EVENT_HUB_NAME = os.getenv("EVENT_HUB_NAME")
CONNECTION_STRING = os.getenv("EVENT_HUB_CONNECTION_STRING")

# Configure the Kafka Producer for Azure Event Hubs SASL authentication
producer = KafkaProducer(
    bootstrap_servers=[f"{EVENTHUBS_NAMESPACE}:9093"],
    security_protocol="SASL_SSL",
    sasl_mechanism="PLAIN",
    sasl_plain_username="$ConnectionString",
    sasl_plain_password=CONNECTION_STRING,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)

# Hospital departments
departments = [
    "Emergency",
    "Surgery",
    "ICU",
    "Pediatrics",
    "Maternity",
    "Oncology",
    "Cardiology",
]

# Gender categories
genders = ["Male", "Female"]


def inject_dirty_data(record):
    # 5% chance to have invalid age
    if random.random() < 0.05:
        record["age"] = random.randint(101, 150)

    # 5% chance to have future admission timestamp
    if random.random() < 0.05:
        record["admission_time"] = (
            datetime.utcnow() + timedelta(hours=random.randint(1, 72))
        ).isoformat()

    return record


def generate_patient_event():
    admission_time = datetime.utcnow() - timedelta(hours=random.randint(0, 72))
    discharge_time = admission_time + timedelta(hours=random.randint(1, 72))

    event = {
        "patient_id": str(uuid.uuid4()),
        "gender": random.choice(genders),
        "age": random.randint(1, 100),
        "department": random.choice(departments),
        "admission_time": admission_time.isoformat(),
        "discharge_time": discharge_time.isoformat(),
        "bed_id": random.randint(1, 500),
        "hospital_id": random.randint(1, 7),  # 7 hospitals in MHA network
    }

    return inject_dirty_data(event)


if __name__ == "__main__":
    print(f"Starting producer... streaming to {EVENT_HUB_NAME}")

    while True:
        event = generate_patient_event()

        # Capture the Future object returned by the send method
        future = producer.send(EVENT_HUB_NAME, event)

        try:
            # Force the script to wait for Azure to acknowledge receipt
            record_metadata = future.get(timeout=10)
            print(
                f"Success! Partition {record_metadata.partition} | Offset {record_metadata.offset} | Patient ID: {event['patient_id']}"
            )
        except Exception as e:
            # If Azure rejects it or the connection fails, it will print here
            print(f"Failed to send to Azure: {e}")

        time.sleep(1)
