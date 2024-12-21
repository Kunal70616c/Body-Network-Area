import pandas as pd
import numpy as np

# Set seed for reproducibility
np.random.seed(42)

# Generate synthetic data
num_samples = 1000
heart_rate = np.random.randint(100, 140, size=num_samples)
body_temp = np.random.uniform(11.0, 41.0, size=num_samples)
accelerometer_x = np.random.uniform(-16000, 21000, size=num_samples)
accelerometer_y = np.random.uniform(-16000, 21000, size=num_samples)
accelerometer_z = np.random.uniform(-16000, 21000, size=num_samples)

# Define thresholds for "sick" condition
heart_rate_threshold = 116
body_temp_threshold = 38.0
accelerometer_threshold = 18000.0

# Generate labels based on thresholds
labels = (
    (heart_rate > heart_rate_threshold) |
    (body_temp > body_temp_threshold) |
    (accelerometer_x > accelerometer_threshold) |
    (accelerometer_y > accelerometer_threshold) |
    (accelerometer_z > accelerometer_threshold)
).astype(int)

# Create a DataFrame
df = pd.DataFrame({
    'heart_rate': heart_rate,
    'body_temp': body_temp,
    'accelerometer_x': accelerometer_x,
    'accelerometer_y': accelerometer_y,
    'accelerometer_z': accelerometer_z,
    'target': labels
})

# Save the synthetic dataset
df.to_csv('health_data.csv', index=False)
print("Synthetic dataset saved as health_data.csv")
