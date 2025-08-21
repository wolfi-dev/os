#!/usr/bin/env python3
"""
Advanced Pydantic Features Tests

This test suite validates advanced Pydantic functionality to ensure the package
supports complex data validation scenarios. It tests:

1. Enum support - Validation of enum fields with string values
2. List and Dict validation - Complex nested data structures with type checking
3. Date/datetime handling - Automatic parsing of date and datetime strings
4. Union types - Fields that can accept multiple types
5. Field validators - Custom validation logic using @field_validator decorator
6. Model config and aliases - Field aliases and configuration options
7. Schema generation - JSON schema generation for API documentation

These tests ensure that the installed Pydantic package provides full functionality
for complex real-world data validation use cases.
"""

from pydantic import BaseModel, Field, ValidationError, validator, field_validator, model_validator
from pydantic.functional_validators import AfterValidator
from typing import List, Dict, Any, Union
from enum import Enum
from datetime import datetime, date
import json


def test_enum_support():
    """Test enum field validation."""
    class Status(str, Enum):
        ACTIVE = "active"
        INACTIVE = "inactive"
        PENDING = "pending"

    class Task(BaseModel):
        name: str
        status: Status
        priority: int = Field(ge=1, le=5)

    # Pydantic accepts string and converts to enum
    task = Task(name="Test Task", status="active", priority=3)
    assert task.status == Status.ACTIVE
    assert task.priority == 3
    print('Enum validation passed')


def test_list_and_dict_validation():
    """Test validation of complex nested structures."""
    class Status(str, Enum):
        ACTIVE = "active"
        INACTIVE = "inactive"
        PENDING = "pending"

    class Task(BaseModel):
        name: str
        status: Status
        priority: int = Field(ge=1, le=5)

    class Project(BaseModel):
        name: str
        tasks: List[Task]
        metadata: Dict[str, Any]

    project = Project(
        name="My Project",
        tasks=[
            {"name": "Task 1", "status": "active", "priority": 1},
            {"name": "Task 2", "status": "pending", "priority": 2}
        ],
        metadata={"version": "1.0", "author": "John", "tags": ["important", "urgent"]}
    )
    
    assert len(project.tasks) == 2
    assert project.tasks[0].name == "Task 1"
    assert project.metadata["version"] == "1.0"
    print('List and Dict validation passed')


def test_date_datetime_handling():
    """Test automatic parsing of date/datetime strings."""
    class Event(BaseModel):
        name: str
        event_date: date
        created_at: datetime
        
    # Pydantic automatically parses date strings
    event = Event(
        name="Conference",
        event_date="2024-12-25",
        created_at="2024-01-15T10:30:00"
    )
    
    assert event.event_date.year == 2024
    assert event.event_date.month == 12
    assert event.created_at.hour == 10
    print('Date/datetime validation passed')


def test_union_types():
    """Test fields that can accept multiple types."""
    class Response(BaseModel):
        data: Union[str, int, List[str]]
        status: int

    # Test with different types
    resp1 = Response(data="success", status=200)
    resp2 = Response(data=42, status=200)
    resp3 = Response(data=["item1", "item2"], status=200)
    
    assert resp1.data == "success"
    assert resp2.data == 42
    assert len(resp3.data) == 2
    print('Union type validation passed')


def test_field_validators():
    """Test custom field validation logic."""
    class EmailModel(BaseModel):
        email: str
        
        @field_validator('email')
        @classmethod
        def validate_email(cls, v):
            if '@' not in v:
                raise ValueError('Invalid email')
            return v.lower()

    # Test email normalization
    email_model = EmailModel(email="USER@EXAMPLE.COM")
    assert email_model.email == "user@example.com"

    # Test invalid email rejection
    try:
        invalid_email = EmailModel(email="notanemail")
        assert False, "Should have raised validation error"
    except ValidationError as e:
        # Expected - Pydantic wraps custom validators in ValidationError
        assert len(e.errors()) > 0
        assert 'Invalid email' in str(e)
    print('Field validator passed')


def test_model_config_and_aliases():
    """Test model configuration and field aliases."""
    class APIResponse(BaseModel):
        model_config = {"populate_by_name": True}
        
        response_code: int = Field(alias="responseCode")
        message: str

    # Can use both field name and alias
    api1 = APIResponse(responseCode=200, message="OK")
    api2 = APIResponse(response_code=404, message="Not Found")
    
    assert api1.response_code == 200
    assert api2.response_code == 404
    print('Model config and aliases passed')


def test_schema_generation():
    """Test JSON schema generation for API documentation."""
    class Status(str, Enum):
        ACTIVE = "active"
        INACTIVE = "inactive"
        PENDING = "pending"

    class Task(BaseModel):
        name: str
        status: Status
        priority: int = Field(ge=1, le=5)

    # Generate JSON schema
    schema = Task.model_json_schema()
    
    assert 'properties' in schema
    assert 'name' in schema['properties']
    assert 'status' in schema['properties']
    print('Schema generation passed')


if __name__ == '__main__':
    # Run all tests
    test_enum_support()
    test_list_and_dict_validation()
    test_date_datetime_handling()
    test_union_types()
    test_field_validators()
    test_model_config_and_aliases()
    test_schema_generation()
    
    print('All advanced Pydantic functional tests passed!')