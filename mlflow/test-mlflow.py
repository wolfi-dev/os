import mlflow
import matplotlib.pyplot as plt
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

# Sample data generation
X = np.random.rand(100, 10)
y = np.random.rand(100) * 100

# Split the data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Define and train the model
model = RandomForestRegressor(n_estimators=10)
model.fit(X_train, y_train)

# Predict on the test set
predictions = model.predict(X_test)

# Calculate MSE
mse = mean_squared_error(y_test, predictions)

# Start an MLflow run
with mlflow.start_run():
    print("Starting MLflow run...")

    # Log parameters (here: number of trees)
    n_estimators = 10
    mlflow.log_param("n_estimators", n_estimators)
    print(f"Logged parameter: n_estimators = {n_estimators}")
    
    # Log metrics (here: MSE)
    mlflow.log_metric("mse", mse)
    print(f"Logged metric: mse = {mse:.4f}")
    
    # Log model
    mlflow.sklearn.log_model(model, "model")
    print("Model logged.")
    
    # Create and save a plot as an artifact
    plt.figure(figsize=(10, 5))
    plt.scatter(y_test, predictions, color='blue')
    plt.xlabel('Actual Values')
    plt.ylabel('Predictions')
    plt.title('Actual vs. Predicted Values')
    plt.grid(True)
    plt.savefig('predictions_plot.png')
    plt.close()
    
    # Log artifacts (here: the plot)
    mlflow.log_artifact('predictions_plot.png')
    print(f"Logged artifact: predictions_plot.png")

    print("MLflow Run completed. Check the MLflow UI for details.")

# Instructions to the user for viewing results.
print("\nRun the command 'mlflow ui' to launch the MLflow Tracking UI at http://localhost:5000.")
