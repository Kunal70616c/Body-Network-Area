from flask import Flask, request, jsonify
import joblib
import numpy as np
import requests

app = Flask(__name__)

# Load the trained model
model = joblib.load('model.pkl')

# Define the endpoint to make predictions
@app.route('/predict', methods=['GET'])
def predict():
    # Fetch data from ThingSpeak
    api_key = 'ER31YYKXAWLEOAXW'
    channel_id = '2574220'
    url = f'https://api.thingspeak.com/channels/{channel_id}/feeds.json?api_key={api_key}&results=1'
    response = requests.get(url)
    data = response.json()
    
   # Extract relevant data from the fetched feed
    feed = data['feeds'][0]

# Map ThingSpeak fields to model features
    heart_rate = float(feed['field5'])  # heart_rate
    body_temp = float(feed['field4'])  # body_temp
    accelerometer_x = int(feed['field1'])  # accelerometer_x
    accelerometer_y = int(feed['field2'])  # accelerometer_y
    accelerometer_z = int(feed['field3'])  # accelerometer_z

# Prepare features for prediction
    features = np.array([[heart_rate, body_temp, accelerometer_x, accelerometer_y, accelerometer_z]], dtype=float)


    # Make a prediction
    prediction = model.predict(features)
    return jsonify({'prediction': int(prediction[0])})

if __name__ == '__main__':
    app.run(debug=True)
