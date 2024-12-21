#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <ESP8266WiFi.h>
#include <ThingSpeak.h>
#include <OneWire.h>
#include <DallasTemperature.h>


MAX30105 particleSensor;
#define MPU_ADDR 0x68

// DS18B20
#define ONE_WIRE_BUS D3  // Pin connected to the DS18B20 data line
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
// WiFi credentials
const char* ssid = "wifi ssid";          // Replace with your Wi-Fi SSID
const char* password = "wifi pass";  // Replace with your Wi-Fi password

// ThingSpeak credentials
unsigned long myChannelNumber = channel id; // Replace with your ThingSpeak Channel Number
const char* myWriteAPIKey = "api key"; // Replace with your ThingSpeak Write API Key

WiFiClient client;

unsigned long lastSendTime = 0; // Last time data was sent to ThingSpeak
const unsigned long sendInterval = 20000; // 20 seconds interval for sending data

// Variables for BPM calculation
static float beatAvg = 0; // Variable to store the average beats per minute
static unsigned long lastBeat = 0; // Variable to store the time of the last beat

void setup() {
  // Initialize Serial
  Serial.begin(115200);
  Wire.begin(D2, D1); // Initialize I2C communication with ESP8266 (D2 for SDA, D1 for SCL)
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0x00);  // Wake up mode
  Wire.endTransmission(true);

  // Initialize WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");

  // Initialize ThingSpeak
  ThingSpeak.begin(client);

  // Initialize MAX30102 sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) { // Initialize the sensor
    Serial.println("MAX30102 was not found. Please check the connections.");
    while (1);
  }

  particleSensor.setup(); // Configure the sensor with default settings
  particleSensor.setPulseAmplitudeRed(0x0A); // Turn Red LED to low
  particleSensor.setPulseAmplitudeGreen(0);  // Turn off Green LED


  // Initialize DS18B20
  sensors.begin();
}

void loop() {
  int16_t ax, ay, az,aa,bb,cc;
  float thresholdWalk = 0.7; // Adjust these thresholds based on testing (g)
float thresholdRun = 1.5; 
 Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);  // Starting address for accelerometer data
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, 6);

  // Combine high and low byte data
  ax = (Wire.read() << 8) | Wire.read();
  ay = (Wire.read() << 8) | Wire.read();
  az = (Wire.read() << 8) | Wire.read();

  // Convert data to g (gravity)
  aa = ax / 16384.0;
  bb = ay / 16384.0;
  cc= az / 16384.0;

  // Read DS18B20 temperature
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);
  long irValue = particleSensor.getIR(); // Read the IR value from the sensor

  if (irValue < 50000) { // If the IR signal is too weak, indicate that the sensor is not in contact with the skin
    Serial.println("No finger detected");
    return;
  }

  //if (checkForBeat(irValue)) {
    // We sensed a beat!
    unsigned long delta = millis() - lastBeat; // Measure duration between beats
    lastBeat = millis();

    float beatsPerMinute = 60.0 / (delta / 1000.0); // Calculate BPM
    beatAvg = (beatAvg * 0.9) + (beatsPerMinute * 0.1); // Simple running average for stabilization
    if(beatsPerMinute<150)
    {
Serial.print("AX: "); Serial.print(ax);
  Serial.print(" | AY: "); Serial.print(ay);
  Serial.print(" | AZ: "); Serial.print(az);
  Serial.print(" | Temperature: "); Serial.print(temperature);
    Serial.print(", BPM=");
    Serial.print(beatsPerMinute);
    if (abs(aa) < 0.2 && abs(bb) < 0.2 && abs(cc) > 0.8) {
    Serial.println("Little moving  ");
  } else if (abs(aa) > thresholdWalk || abs(bb) > thresholdWalk || abs(cc) > thresholdWalk) {
    Serial.println("Walking");
  } else if (abs(aa) > thresholdRun || abs(bb) > thresholdRun || abs(cc) > thresholdRun) {
    Serial.println("Running  ");
  } else {
    Serial.println("Standing  ");
  }

    /*Serial.print(", IR=");
    Serial.println(irValue);*/
    // Send BPM to ThingSpeak if the interval has passed
    if (millis() - lastSendTime >= sendInterval) {
      sendToThingSpeak(beatsPerMinute,ax,ay,az,temperature);
      lastSendTime = millis(); // Update last send time
    }
  }
}

void sendToThingSpeak(float bpm,int16_t a,int16_t b,int16_t c,float t) {
  if (WiFi.status() == WL_CONNECTED) {
    ThingSpeak.setField(1, a);
  ThingSpeak.setField(2, b);
  ThingSpeak.setField(3, c);
  ThingSpeak.setField(4, t);
    ThingSpeak.setField(5, bpm);
    int response = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
    if (response == 200) {
      Serial.println("Data sent to ThingSpeak successfully");
    } else {
      Serial.println("Problem sending data to ThingSpeak. HTTP error code: " + String(response));
    }
  } else {
    Serial.println("WiFi not connected");
  }
}