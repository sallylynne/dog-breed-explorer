import dlt
import os
from dlt.sources.helpers import requests

# Force the partition layout in the environment variables
os.environ["DESTINATION__FILESYSTEM__LAYOUT"] = "{table_name}/{YYYY}/{MM}/{DD}/{load_id}.{file_id}.{ext}"


@dlt.resource(name="dog_api_raw", write_disposition="replace")
def fetch_dog_breeds():
	api_key = dlt.secrets.get("sources.rest_api.api_key")
	url = "https://api.thedogapi.com/v1/breeds"
	headers = {"x-api-key": api_key}
	response = requests.get(url, headers=headers)
	response.raise_for_status()
	yield response.json()

if __name__ == "__main__":
	pipeline = dlt.pipeline(
	pipeline_name="dog_breed_explorer",
	destination="bigquery",
	staging="filesystem",  # This tells dlt to use GCS first
	dataset_name="bronze",
	)
	load_info = pipeline.run(fetch_dog_breeds())
	print(load_info)
