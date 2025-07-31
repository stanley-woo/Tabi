import os
import sys
# Ensure the project root is on sys.path so "import backend.app.main" works
sys.path.insert(0,os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Force SQLite in-memory for all database operations
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel

from backend.app.main import app
from backend.app.database import init_db, engine
from backend.app.models import Itinerary


@pytest.fixture(autouse=True)
def setup_database():
    """Reset the in-memory DB before each test."""
    init_db()
    yield
    SQLModel.metadata.drop_all(engine)


@pytest.fixture
def client():
    """Provide a TestClient for the FastAPI app."""
    return TestClient(app)


@pytest.fixture
def sample_itinerary():
    """Seed a single itinerary for each test, avoiding UNIQUE constraint collisions."""
    with Session(engine) as session:
        itin = Itinerary(title="Test Trip",slug="test-trip",creator_id=1)
        session.add(itin)
        session.commit()
        session.refresh(itin)
        return itin


def test_list_empty_days(client, sample_itinerary):
    """GET on a fresh itinerary should return an empty list of days."""
    response = client.get(f"/itineraries/{sample_itinerary.id}/days/")
    assert response.status_code == 200
    assert response.json() == []


def test_create_day_group(client, sample_itinerary):
    """POST should add a new day group and return its data."""
    payload = {"date": "2025-08-01", "order": 0, "title": "Arrival"}
    response = client.post(f"/itineraries/{sample_itinerary.id}/days/", json=payload)
    assert response.status_code == 201

    data = response.json()
    assert data["title"] == "Arrival"
    assert data["itinerary_id"] == sample_itinerary.id
    assert "id" in data


def test_delete_day_group(client, sample_itinerary):
    """DELETE should remove the only day, and subsequent GET returns empty."""
    # Create a single day
    payload = {"date": "2025-08-02", "order": 0, "title": "Day 2"}
    created = client.post(f"/itineraries/{sample_itinerary.id}/days/", json=payload).json()
    day_id = created["id"]

    # Delete it
    delete_resp = client.delete(f"/itineraries/{sample_itinerary.id}/days/{day_id}")
    assert delete_resp.status_code == 204

    # Confirm empty again
    list_resp = client.get(f"/itineraries/{sample_itinerary.id}/days/")
    assert list_resp.json() == []


def test_delete_nonexistent_day(client, sample_itinerary):
    """Deleting a missing ID should yield a 404."""
    response = client.delete(f"/itineraries/{sample_itinerary.id}/days/999")
    assert response.status_code == 404


def test_delete_wrong_itinerary(client, sample_itinerary):
    """
    Attempting to delete a day under the wrong itinerary
    should yield a 400 Bad Request.
    """
    payload = {"date": "2025-08-03", "order": 0, "title": "Oops"}
    created = client.post(f"/itineraries/{sample_itinerary.id}/days/", json=payload).json()
    day_id = created["id"]

    response = client.delete(f"/itineraries/{sample_itinerary.id + 1}/days/{day_id}")
    assert response.status_code == 400


def test_reorder_day_groups(client, sample_itinerary):
    """
    PATCH /reorder should update the order of day groups
    and return them in the new sequence.
    """
    ids = []
    for idx, title in enumerate(["Day A", "Day B", "Day C"], start=1):
        payload = {"date": f"2025-08-0{idx}","order": 0,"title": title}
        created = client.post(f"/itineraries/{sample_itinerary.id}/days/", json=payload).json()
        ids.append(created["id"])

    response = client.patch(f"/itineraries/{sample_itinerary.id}/days/reorder",json=list(reversed(ids)))
    assert response.status_code == 200

    titles = [dg["title"] for dg in response.json()]
    assert titles == ["Day C", "Day B", "Day A"]