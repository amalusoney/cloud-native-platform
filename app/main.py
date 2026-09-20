import os
import sys
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Text
from sqlalchemy.orm import declarative_base, sessionmaker, Session

# Database Configuration with PostgreSQL or SQLite fallback
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    # Fallback to local SQLite for seamless standalone container execution
    DATABASE_URL = "sqlite:///./tasks.db"
    connect_args = {"check_same_thread": False}
else:
    connect_args = {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Model
class TaskModel(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    completed = Column(Boolean, default=False)

# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic Schemas
class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, example="Deploy to EKS")
    description: Optional[str] = Field(None, example="Automated deployment via GitOps")
    completed: bool = Field(default=False)

class TaskResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    completed: bool

    class Config:
        from_attributes = True

# FastAPI Application
app = FastAPI(
    title="Cloud-Native Task API",
    version="1.0.0",
    description="Lightweight microservice designed for GitOps CI/CD pipeline demonstrations on AWS EKS.",
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/", tags=["Root"])
def root():
    return {
        "service": "cloud-native-task-api",
        "version": "1.0.0",
        "status": "running",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "documentation": "/docs"
    }

# Global flag for K8s self-healing / liveness probe experiments
_is_healthy = True

@app.get("/health", tags=["Health"])
def health():
    """Liveness & Readiness probe endpoint for Kubernetes / Docker."""
    if not _is_healthy:
        raise HTTPException(status_code=500, detail="Simulated container failure for K8s self-healing test")
    return {"status": "healthy", "database": "connected"}

@app.post("/health/fail", tags=["Health"])
def fail_health():
    """Deliberately fail health checks to demonstrate Kubelet probe recovery."""
    global _is_healthy
    _is_healthy = False
    return {"status": "unhealthy", "message": "Health probe is now returning 500"}

@app.post("/health/recover", tags=["Health"])
def recover_health():
    """Restore health check status."""
    global _is_healthy
    _is_healthy = True
    return {"status": "healthy", "message": "Health probe restored to 200"}

@app.get("/stress", tags=["Health"])
def stress_cpu(duration: int = 5):
    """Simulate CPU load for Horizontal Pod Autoscaler (HPA) testing."""
    import time
    end_time = time.time() + duration
    while time.time() < end_time:
        _ = 3.14159 * 2.71828 * 999999
    return {"status": "stress_complete", "duration_seconds": duration}


@app.get("/api/v1/tasks", response_model=List[TaskResponse], tags=["Tasks"])
def list_tasks(db: Session = Depends(get_db)):
    return db.query(TaskModel).all()

@app.post("/api/v1/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED, tags=["Tasks"])
def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    db_task = TaskModel(title=task.title, description=task.description, completed=task.completed)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@app.get("/api/v1/tasks/{task_id}", response_model=TaskResponse, tags=["Tasks"])
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(TaskModel).filter(TaskModel.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.delete("/api/v1/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Tasks"])
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(TaskModel).filter(TaskModel.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return None
