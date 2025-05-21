import requests
import time
import random

url = "http://api-fastapi:8000/predict"

while True:
    sample = [[random.uniform(4.0, 8.0) for _ in range(4)]]
    try:
        response = requests.post(url, json={"data": sample})
        print(response.json())
    except Exception as e:
        print("Error:", e)
    time.sleep(1)
