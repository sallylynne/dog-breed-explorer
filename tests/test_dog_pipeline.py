import pytest
from unittest.mock import MagicMock, patch

# Minimal sample record matching the Dog API response shape
SAMPLE_BREED = {
    "id": 1,
    "name": "Affenpinscher",
    "temperament": "Stubborn, Curious, Playful, Adventurous, Active, Fun-loving",
    "life_span": "10 - 12 years",
    "weight": {"imperial": "6 - 13", "metric": "3 - 6"},
    "height": {"imperial": "9 - 11.5", "metric": "23 - 29"},
    "breed_group": "Toy Group",
    "origin": "Germany, France",
    "reference_image_id": "BJa4kxc4X",
}

# Fields the downstream dbt staging model depends on
EXPECTED_FIELDS = {"id", "name", "temperament", "life_span", "weight", "height"}


def test_fetch_dog_breeds_schema():
    """Yielded records contain the fields the staging model depends on."""
    mock_response = MagicMock()
    mock_response.json.return_value = [SAMPLE_BREED]
    mock_response.raise_for_status.return_value = None

    with patch("dog_pipeline.requests.get", return_value=mock_response), \
         patch("dlt.secrets.get", return_value="test-api-key"):
        import dog_pipeline
        results = list(dog_pipeline.fetch_dog_breeds())

    assert len(results) > 0
    record = results[0]
    for field in EXPECTED_FIELDS:
        assert field in record, f"Expected field '{field}' missing from API response"


def test_fetch_dog_breeds_raises_on_http_error():
    """Pipeline propagates HTTP errors rather than silently swallowing them."""
    mock_response = MagicMock()
    mock_response.raise_for_status.side_effect = Exception("403 Forbidden")

    with patch("dog_pipeline.requests.get", return_value=mock_response), \
         patch("dlt.secrets.get", return_value="test-api-key"):
        import dog_pipeline
        with pytest.raises(Exception, match="403 Forbidden"):
            list(dog_pipeline.fetch_dog_breeds())
