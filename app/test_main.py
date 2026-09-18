from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "cloud-native-task-api"
    assert data["version"] == "1.0.0"
    assert data["status"] == "running"

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"

def test_create_and_get_task():
    # Create task
    payload = {"title": "Test CI/CD Pipeline", "description": "Phase 4 Automated Verification"}
    post_response = client.post("/api/v1/tasks", json=payload)
    assert post_response.status_code == 201
    created_task = post_response.json()
    assert created_task["title"] == "Test CI/CD Pipeline"
    task_id = created_task["id"]

    # Get task by ID
    get_response = client.get(f"/api/v1/tasks/{task_id}")
    assert get_response.status_code == 200
    fetched_task = get_response.json()
    assert fetched_task["id"] == task_id
    assert fetched_task["title"] == "Test CI/CD Pipeline"

def test_get_nonexistent_task():
    response = client.get("/api/v1/tasks/999999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Task not found"
