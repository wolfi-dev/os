import django
from django.conf import settings
from django.db import models

# Setup minimal Django configuration
def setup_django_environment():
    settings.configure(
        DEBUG=True,
        INSTALLED_APPS=['__main__'],
        DATABASES={
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': ':memory:',
            }
        }
    )
    django.setup()

def define_and_test_model():
    # Define a simple Django model
    class TestModel(models.Model):
        name = models.CharField(max_length=100)

    # Test function
    try:
        # Create the database tables
        with django.db.connection.schema_editor() as schema_editor:
            schema_editor.create_model(TestModel)

        # Create and query a test object
        TestModel.objects.create(name="Test Name")
        test_obj = TestModel.objects.get(name="Test Name")

        print(f"Test object found: {test_obj.name}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    setup_django_environment()
    define_and_test_model()



