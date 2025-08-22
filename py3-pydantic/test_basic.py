#!/usr/bin/env python3
"""
Basic Pydantic Functionality Tests

This test suite validates the core functionality of the Pydantic package to ensure
it's properly installed and working. It tests:

1. Basic model validation - Creating models with typed fields and validating data types
2. Invalid data rejection - Ensuring ValidationError is raised for invalid data
3. JSON serialization - Testing model_dump_json() and model_validate_json() methods
4. Nested models - Validating that nested model structures work correctly
5. Optional fields and defaults - Testing Optional type hints and default values

These tests ensure that the installed Pydantic package can perform its fundamental
operations of data validation and serialization using Python type hints.
"""

from pydantic import BaseModel, Field, ValidationError
from typing import Optional
from datetime import datetime
import json


def test_basic_model_validation():
    """Test basic model creation with type validation."""
    class User(BaseModel):
        id: int
        name: str
        email: str
        age: int = Field(gt=0, le=150)
        is_active: bool = True

    # Valid user
    user = User(id=1, name='John Doe', email='john@example.com', age=30)
    assert user.id == 1
    assert user.name == 'John Doe'
    assert user.age == 30
    print('Basic model validation passed')


def test_invalid_data_rejection():
    """Test that invalid data raises ValidationError."""
    class User(BaseModel):
        id: int
        name: str
        email: str
        age: int = Field(gt=0, le=150)
        is_active: bool = True

    try:
        # Invalid: id is string instead of int, age exceeds max
        invalid_user = User(id='not_an_int', name='Jane', email='jane@example.com', age=200)
        assert False, 'Should have raised ValidationError'
    except ValidationError as e:
        assert len(e.errors()) > 0
        print('Invalid data rejection passed')


def test_json_serialization():
    """Test JSON serialization and deserialization."""
    class User(BaseModel):
        id: int
        name: str
        email: str
        age: int = Field(gt=0, le=150)
        is_active: bool = True

    user = User(id=1, name='John Doe', email='john@example.com', age=30)
    
    # Serialize to JSON
    json_str = user.model_dump_json()
    
    # Deserialize from JSON
    user_from_json = User.model_validate_json(json_str)
    assert user_from_json.id == user.id
    assert user_from_json.name == user.name
    print('JSON serialization/deserialization passed')


def test_nested_models():
    """Test nested model validation."""
    class Address(BaseModel):
        street: str
        city: str
        country: str
        
    class UserWithAddress(BaseModel):
        name: str
        address: Address

    # Pydantic automatically validates nested dict as Address model
    user_with_addr = UserWithAddress(
        name='Alice',
        address={'street': '123 Main St', 'city': 'NYC', 'country': 'USA'}
    )
    assert user_with_addr.address.city == 'NYC'
    print('Nested model validation passed')


def test_optional_fields_and_defaults():
    """Test optional fields and default values."""
    class Config(BaseModel):
        debug: bool = False
        timeout: Optional[int] = None
        max_retries: int = 3

    # Create instance without providing any values
    config = Config()
    assert config.debug is False
    assert config.timeout is None
    assert config.max_retries == 3
    print('Optional fields and defaults passed')


if __name__ == '__main__':
    # Run all tests
    test_basic_model_validation()
    test_invalid_data_rejection()
    test_json_serialization()
    test_nested_models()
    test_optional_fields_and_defaults()
    
    print('All basic Pydantic functional tests passed!')