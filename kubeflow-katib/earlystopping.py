#!/usr/bin/env python3
import time
import argparse

def train_model(max_epochs, patience):
    best_metric = None
    epochs_without_improvement = 0

    for epoch in range(1, max_epochs + 1):
        # For epochs 1-5, the metric increases.
        # After that, it plateaus so that no further improvement occurs.
        if epoch <= 5:
            metric = 0.5 + epoch * 0.1  # increasing metric
        else:
            metric = 1.0  # plateau value

        # Print metric in a format Katib can parse
        print(f"Epoch: {epoch} - Metric: {metric:.4f}", flush=True)

        # Check if the metric improved
        if best_metric is None or metric > best_metric:
            best_metric = metric
            epochs_without_improvement = 0
        else:
            epochs_without_improvement += 1

        # If no improvement for 'patience' epochs, trigger early stopping.
        if epochs_without_improvement >= patience:
            print(f"Early stopping triggered at epoch {epoch}", flush=True)
            return best_metric

        # Simulate training time
        time.sleep(0.1)

    return best_metric

def main():
    parser = argparse.ArgumentParser(description="Test Katib early stopping simulation.")
    parser.add_argument('--max_epochs', type=int, default=10, help='Maximum number of epochs to run')
    parser.add_argument('--patience', type=int, default=2, help='Number of epochs with no improvement to wait before stopping')
    args = parser.parse_args()

    final_metric = train_model(args.max_epochs, args.patience)
    print(f"Final best metric: {final_metric:.4f}", flush=True)

if __name__ == '__main__':
    main()
