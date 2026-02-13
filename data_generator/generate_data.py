import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import uuid
from datetime import datetime, timedelta
import random
import json

np.random.seed(42)
random.seed(42)

N_USERS = 8000
START_DATE = datetime(2024, 1, 1)

# ------------------
# USERS
# ------------------
users = []
for i in range(N_USERS):
  signup_timestamp = START_DATE + timedelta(days=np.random.poisson(30))
  users.append({
    "user_id": str(uuid.uuid4()),
    "signup_timestamp": signup_timestamp,
    "acquisition_channel": random.choice(
        ["organic", "paid_search", "referral", "sales"]
    ),
    "country": random.choice(["US", "CA", "GB", "DE", "IN"])
  })
users_df = pd.DataFrame(users)

# ------------------
# EVENTS
# ------------------
events = []
event_names = [
    "signup",
    "onboarding_completed",
    "feature_a_used",
    "feature_b_used",
    "upgrade",
    "cancel"
]
for _, user in users_df.iterrows():
    user_id = user["user_id"]
    ts = user["signup_timestamp"]

    experiment_variant = random.choice(["A","B"])
    activated = False

    #signup event
    events.append({
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "event_name": "signup",
        "device_type": random.choice(["web", "mobile"]),
        "plan_type": "free",
        "experiment_variant": experiment_variant,
        "event_properties": json.dumps({"source": user["acquisition_channel"], "country": user["country"]})
    })

    #onboarding
    onboarding_prob = 0.55 if experiment_variant == "A" else 0.65
    if random.random() < onboarding_prob:
        activated = True
        ts += timedelta(days=random.randint(0, 3))
        events.append({
            "event_id": str(uuid.uuid4()),
            "user_id": user["user_id"],
            "event_name": "onboarding_completed",
            "event_timestamp": ts,
            "device_type": random.choice(["web", "mobile"]),
            "event_properties": json.dumps({"steps_completed": 5})
        })
    # feature usage
    for feature in ["feature_a_used", "feature_b_used"]:
        usage_prob = 0.4 if activated else 0.1
        if random.random() < usage_prob:
            ts += timedelta(days=random.randint(1, 14))
            events.append({
                "event_id": str(uuid.uuid4()),
                "user_id": user["user_id"],
                "event_name": feature,
                "event_timestamp": ts,
                "device_type": random.choice(["web", "mobile"]),
                "plan_type": "free",
                "experiment_variant": experiment_variant,
                "event_properties": json.dumps({"usage_count": random.randint(1, 10)})
            })
    #upgrade
    upgrade_prob = 0.25 if activated else 0.05
    if random.random() < upgrade_prob:
        ts += timedelta(days=random.randint(7, 30))
        events.append({
            "event_id": str(uuid.uuid4()),
            "user_id": user_id,
            "event_name": "upgrade",
            "event_timestamp": ts,
            "device_type": random.choice(["web", "mobile"]),
            "plan_type": "pro",
            "experiment_variant": experiment_variant,
            "event_properties": json.dumps({"from_plan": "free", "to_plan": "pro"})
        })
    #cancel
    if random.random() < 0.1:
        ts += timedelta(days=random.randint(30, 90))
        events.append({
            "event_id": str(uuid.uuid4()),
            "user_id": user_id,
            "event_name": "cancel",
            "event_timestamp": ts,
            "device_type": random.choice(["web", "mobile"]),
            "plan_type": "pro",
            "experiment_variant": experiment_variant,
            "event_properties": json.dumps({"reason": random.choice(["price", "value", "other"])})

        }
        )
events_df = pd.DataFrame(events)

# ------------------
# SUBSCRIPTIONS
# ------------------
subs = []
for _, event in events_df[events_df["event_name"] == "upgrade"].iterrows():
    start_date = event["event_timestamp"]
    churned = random.random() < 0.2
    end_date = start_date + timedelta(days=random.randint(30, 120)) if churned else None

    subs.append({
        "subscription_id": str(uuid.uuid4()),
        "user_id": event["user_id"],
        "plan": "pro",
        "start_date": start_date,
        "end_date": end_date,
        "monthly_revenue": 49.0,
        "status": "canceled" if churned else "active"
            })
subs_df = pd.DataFrame(subs)

# ------------------
# SAVE FILES
# ------------------
users_df.to_csv("raw_users.csv", index=False)
events_df.to_csv("raw_events.csv", index=False)
subs_df.to_csv("raw_subscriptions.csv", index=False)

print("Data generation complete.")