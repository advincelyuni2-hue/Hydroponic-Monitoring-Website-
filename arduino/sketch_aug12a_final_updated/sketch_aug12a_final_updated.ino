#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <math.h>

// =====================================================
// OPERATING MODE
// =====================================================

// true  = calibration only; no buffering or uploads
// false = normal monitoring and five-minute uploads
const bool CALIBRATION_MODE = true;

enum CalibrationTarget {
  PH_ONLY,
  EC_ONLY,
  PH_AND_EC
};

// Change only this line when selecting what to calibrate.
// PH_ONLY   = pH 4.00 and pH 6.86; EC is skipped.
// EC_ONLY   = EC 1.413 and EC 12.88; pH is skipped.
// PH_AND_EC = diagnostic use only; reads both sensors.
const CalibrationTarget CALIBRATION_TARGET = PH_ONLY;

// =====================================================
// WIFI AND SUPABASE
// =====================================================

const char* WIFI_SSID = "PLDT_Home_BB3C1";
const char* WIFI_PASSWORD = "pldthome";

const char* SUPABASE_REST_URL =
  "https://rhgcxqgcxnaxgwksdyks.supabase.co/rest/v1/";

const char* SUPABASE_PUBLISHABLE_KEY =
  "sb_publishable_JCVLqWnQuQKzrnFGWUDJcQ_Lax526-E";

// =====================================================
// PIN DEFINITIONS
// =====================================================

#define DHT_PIN 4
#define DHT_TYPE DHT22

#define PH_PIN 34
#define EC_PIN 35

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDRESS 0x3C

// =====================================================
// FINAL pH CALIBRATION
// =====================================================

// Averaged calibration voltages:
//
// pH 4.00 = 3.087820 V (mean of 15 stable readings)
// pH 6.86 = 2.595250 V (mean of the final 10 stable readings)

const double PH_LOW_REFERENCE = 4.00;
const double PH_HIGH_REFERENCE = 6.86;

const double PH4_VOLTAGE = 3.087820;
const double PH686_VOLTAGE = 2.595250;

const double PH_SLOPE =
  (PH4_VOLTAGE - PH686_VOLTAGE) /
  (PH_HIGH_REFERENCE - PH_LOW_REFERENCE);

// =====================================================
// FINAL EC CALIBRATION
// =====================================================

// Voltages normalized to 25 C:
//
// 1.413 mS/cm = 0.836311 V
// 12.88 mS/cm = 1.721006 V

const double EC_LOW_REFERENCE = 1.413;
const double EC_HIGH_REFERENCE = 12.88;

const double EC_LOW_VOLTAGE_25 = 0.836311;
const double EC_HIGH_VOLTAGE_25 = 1.721006;

const double EC_SLOPE =
  (EC_HIGH_REFERENCE - EC_LOW_REFERENCE) /
  (EC_HIGH_VOLTAGE_25 - EC_LOW_VOLTAGE_25);

const double EC_INTERCEPT =
  EC_LOW_REFERENCE -
  (EC_SLOPE * EC_LOW_VOLTAGE_25);

const double EC_TEMPERATURE_COEFFICIENT = 0.019;

// =====================================================
// TIMING
// =====================================================

// pH at 0 seconds
// Temperature and EC at 5 seconds
// Next cycle at 10 seconds

const unsigned long SENSOR_CYCLE_INTERVAL = 10000UL;
const unsigned long PH_TO_EC_DELAY = 5000UL;
const unsigned long FIVE_MINUTE_INTERVAL = 300000UL;
const unsigned long WIFI_RETRY_INTERVAL = 10000UL;

// =====================================================
// ADC SETTINGS
// =====================================================

const int ADC_SAMPLE_COUNT = 20;
const int ADC_SAMPLE_DELAY_MS = 5;
const int ADC_SETTLE_DELAY_MS = 50;

// =====================================================
// FIVE-MINUTE BUFFER
// =====================================================

const int MAX_HISTORY_SAMPLES = 40;

double phSamples[MAX_HISTORY_SAMPLES];
double ecSamples[MAX_HISTORY_SAMPLES];
double temperatureSamples[MAX_HISTORY_SAMPLES];

int historySampleCount = 0;

// =====================================================
// LATEST VALUES
// =====================================================

double latestPH = NAN;
double latestEC = NAN;
double latestTemperature = NAN;

double latestPHVoltage = NAN;
double latestECVoltage = NAN;

// =====================================================
// TIMERS AND SENSOR STATE
// =====================================================

unsigned long sensorCycleStartedAt = 0;
unsigned long lastFiveMinuteUpload = 0;
unsigned long lastWiFiRetry = 0;

enum SensorState {
  READY_FOR_PH,
  WAITING_FOR_EC
};

SensorState sensorState = READY_FOR_PH;

// =====================================================
// OBJECTS
// =====================================================

DHT dht(DHT_PIN, DHT_TYPE);

Adafruit_SSD1306 display(
  SCREEN_WIDTH,
  SCREEN_HEIGHT,
  &Wire,
  -1
);

bool oledReady = false;

// =====================================================
// FUNCTION DECLARATIONS
// =====================================================

void maintainWiFi();

void startPHCycle(unsigned long currentTime);
void completeECCycle();
void storeCompleteSample();

double readPHVoltage();
double readECVoltage();
double readAverageVoltage(uint8_t pin);

double calculatePH(double voltage);

double calculateEC(
  double voltage,
  double temperature
);

void processFiveMinuteHistory();
void resetHistoryBuffer();

double calculateMean(
  const double values[],
  int count
);

double calculateMinimum(
  const double values[],
  int count
);

double calculateMaximum(
  const double values[],
  int count
);

double calculateMedian(
  const double values[],
  int count
);

double calculateStandardDeviation(
  const double values[],
  int count,
  double mean
);

bool sendHistoryToSupabase(
  double averagePH,
  double medianPH,
  double minimumPH,
  double maximumPH,
  double latestPHValue,
  double standardDeviationPH,

  double averageEC,
  double medianEC,
  double minimumEC,
  double maximumEC,
  double latestECValue,
  double standardDeviationEC,

  double averageTemperature,
  double medianTemperature,
  double minimumTemperature,
  double maximumTemperature,
  double latestTemperatureValue,
  double standardDeviationTemperature,

  int sampleCount
);

void updateOLED();

// =====================================================
// SETUP
// =====================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("====================================");
  Serial.println("HYDROPONICS MONITOR STARTING");
  Serial.println("====================================");

  if (CALIBRATION_MODE) {
    Serial.println("[MODE] CALIBRATION MODE");
    Serial.println("[MODE] Supabase uploads disabled.");

    if (CALIBRATION_TARGET == PH_ONLY) {
      Serial.println("[MODE] Calibration target: pH only.");
    } else if (CALIBRATION_TARGET == EC_ONLY) {
      Serial.println("[MODE] Calibration target: EC only.");
    } else {
      Serial.println("[MODE] Calibration target: pH and EC.");
    }
  } else {
    Serial.println("[MODE] MONITORING MODE");
    Serial.println("[MODE] Five-minute uploads enabled.");
  }

  dht.begin();
  Wire.begin();

  oledReady = display.begin(
    SSD1306_SWITCHCAPVCC,
    OLED_ADDRESS
  );

  if (oledReady) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Hydroponics");

    if (CALIBRATION_MODE) {
      display.println("Calibration mode");
    } else {
      display.println("Starting...");
    }

    display.display();
  } else {
    Serial.println("[OLED] Initialization failed.");
  }

  analogReadResolution(12);

  analogSetPinAttenuation(
    PH_PIN,
    ADC_11db
  );

  analogSetPinAttenuation(
    EC_PIN,
    ADC_11db
  );

  Serial.println();
  Serial.println("Calibration constants:");

  Serial.printf(
    "[CAL] pH 4.00 voltage: %.6f V\n",
    PH4_VOLTAGE
  );

  Serial.printf(
    "[CAL] pH 6.86 voltage: %.6f V\n",
    PH686_VOLTAGE
  );

  Serial.printf(
    "[CAL] pH slope: %.6f V/pH\n",
    PH_SLOPE
  );

  Serial.printf(
    "[CAL] EC low voltage at 25 C: %.6f V\n",
    EC_LOW_VOLTAGE_25
  );

  Serial.printf(
    "[CAL] EC high voltage at 25 C: %.6f V\n",
    EC_HIGH_VOLTAGE_25
  );

  Serial.printf(
    "[CAL] EC slope: %.6f\n",
    EC_SLOPE
  );

  Serial.printf(
    "[CAL] EC intercept: %.6f\n",
    EC_INTERCEPT
  );

  if (CALIBRATION_MODE) {
    WiFi.mode(WIFI_OFF);
    Serial.println("[WiFi] Disabled during calibration.");
  } else {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    Serial.print("[WiFi] Connecting");

    unsigned long connectionStartedAt = millis();

    while (
      WiFi.status() != WL_CONNECTED &&
      millis() - connectionStartedAt < 20000UL
    ) {
      delay(500);
      Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println();
      Serial.println("[WiFi] Connected.");

      Serial.print("[WiFi] IP: ");
      Serial.println(WiFi.localIP());
    } else {
      Serial.println();
      Serial.println("[WiFi] Connection timeout.");
      Serial.println("[WiFi] Sensors will continue.");
    }
  }

  unsigned long currentTime = millis();

  sensorCycleStartedAt = currentTime;
  lastFiveMinuteUpload = currentTime;

  startPHCycle(currentTime);
}

// =====================================================
// MAIN LOOP
// =====================================================

void loop() {
  unsigned long currentTime = millis();

  maintainWiFi();

  if (
    sensorState == WAITING_FOR_EC &&
    currentTime - sensorCycleStartedAt >=
      PH_TO_EC_DELAY
  ) {
    completeECCycle();
  }

  if (
    sensorState == READY_FOR_PH &&
    currentTime - sensorCycleStartedAt >=
      SENSOR_CYCLE_INTERVAL
  ) {
    startPHCycle(currentTime);
  }

  if (
    !CALIBRATION_MODE &&
    currentTime - lastFiveMinuteUpload >=
      FIVE_MINUTE_INTERVAL
  ) {
    processFiveMinuteHistory();

    lastFiveMinuteUpload +=
      FIVE_MINUTE_INTERVAL;

    if (
      currentTime - lastFiveMinuteUpload >=
        FIVE_MINUTE_INTERVAL
    ) {
      lastFiveMinuteUpload = currentTime;
    }
  }

  updateOLED();
  delay(50);
}

// =====================================================
// WIFI
// =====================================================

void maintainWiFi() {
  if (CALIBRATION_MODE) {
    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  unsigned long currentTime = millis();

  if (
    currentTime - lastWiFiRetry <
    WIFI_RETRY_INTERVAL
  ) {
    return;
  }

  lastWiFiRetry = currentTime;

  Serial.println("[WiFi] Reconnecting...");

  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

// =====================================================
// pH MEASUREMENT
// =====================================================

void startPHCycle(unsigned long currentTime) {
  sensorCycleStartedAt = currentTime;

  Serial.println();
  Serial.println("---------- SENSOR CYCLE ----------");

  if (
    CALIBRATION_MODE &&
    CALIBRATION_TARGET == EC_ONLY
  ) {
    Serial.println("[CAL] pH skipped; EC-only calibration.");
    completeECCycle();
    return;
  }

  Serial.println("[SENSOR] Reading pH...");

  latestPHVoltage = readPHVoltage();
  latestPH = calculatePH(latestPHVoltage);

  if (!isnan(latestPH)) {
    Serial.printf(
      "[pH] Voltage: %.6f V\n",
      latestPHVoltage
    );

    Serial.printf(
      "[pH] Calculated value: %.6f\n",
      latestPH
    );
  } else {
    Serial.println("[pH] Invalid reading.");
  }

  if (
    CALIBRATION_MODE &&
    CALIBRATION_TARGET == PH_ONLY
  ) {
    Serial.println("[CAL] EC skipped; pH-only calibration.");
    Serial.println("[CAL] Reading not stored or uploaded.");
    sensorState = READY_FOR_PH;
    return;
  }

  Serial.println("[SENSOR] Waiting 5 seconds before EC...");
  sensorState = WAITING_FOR_EC;
}

// =====================================================
// TEMPERATURE AND EC MEASUREMENT
// =====================================================

void completeECCycle() {
  Serial.println(
    "[SENSOR] Reading temperature and EC..."
  );

  double temperatureForCompensation =
    dht.readTemperature();

  if (!isnan(temperatureForCompensation)) {
    latestTemperature =
      temperatureForCompensation;

    Serial.printf(
      "[TEMP] Value: %.2f C\n",
      latestTemperature
    );
  } else {
    Serial.println("[TEMP] DHT22 read failed.");

    if (!isnan(latestTemperature)) {
      temperatureForCompensation =
        latestTemperature;

      Serial.printf(
        "[TEMP] Previous value used for EC: %.2f C\n",
        temperatureForCompensation
      );
    } else {
      temperatureForCompensation = 25.0;

      Serial.println(
        "[TEMP] Using 25 C for EC compensation only."
      );
    }
  }

  delay(100);

  latestECVoltage = readECVoltage();

  latestEC = calculateEC(
    latestECVoltage,
    temperatureForCompensation
  );

  if (!isnan(latestEC)) {
    Serial.printf(
      "[EC] Voltage: %.6f V\n",
      latestECVoltage
    );

    Serial.printf(
      "[EC] Calculated value: %.6f mS/cm\n",
      latestEC
    );
  } else {
    Serial.println("[EC] Invalid reading.");
  }

  if (CALIBRATION_MODE) {
    Serial.println(
      "[CAL] Reading not stored or uploaded."
    );
  } else if (
    !isnan(latestPH) &&
    !isnan(latestEC) &&
    !isnan(latestTemperature)
  ) {
    storeCompleteSample();
  } else {
    Serial.println(
      "[BUFFER] Incomplete sample not stored."
    );
  }

  sensorState = READY_FOR_PH;
}

// =====================================================
// ADC READING
// =====================================================

double readPHVoltage() {
  return readAverageVoltage(PH_PIN);
}

double readECVoltage() {
  return readAverageVoltage(EC_PIN);
}

double readAverageVoltage(uint8_t pin) {
  delay(ADC_SETTLE_DELAY_MS);

  // Discard initial reads after switching channels.
  analogRead(pin);
  delay(5);

  analogRead(pin);
  delay(5);

  analogRead(pin);
  delay(5);

  uint32_t rawTotal = 0;

  for (
    int index = 0;
    index < ADC_SAMPLE_COUNT;
    index++
  ) {
    rawTotal += analogRead(pin);
    delay(ADC_SAMPLE_DELAY_MS);
  }

  double averageRaw =
    (double)rawTotal /
    (double)ADC_SAMPLE_COUNT;

  double voltage =
    averageRaw * (3.3 / 4095.0);

  if (pin == PH_PIN) {
    Serial.printf(
      "[pH ADC] Raw average: %.2f\n",
      averageRaw
    );
  } else if (pin == EC_PIN) {
    Serial.printf(
      "[EC ADC] Raw average: %.2f\n",
      averageRaw
    );
  }

  return voltage;
}

// =====================================================
// pH CALCULATION
// =====================================================

double calculatePH(double voltage) {
  if (
    isnan(voltage) ||
    fabs(PH_SLOPE) < 0.000001
  ) {
    Serial.println(
      "[pH] Invalid voltage or calibration slope."
    );

    return NAN;
  }

  double calculatedPH =
    PH_HIGH_REFERENCE -
    (
      (voltage - PH686_VOLTAGE) /
      PH_SLOPE
    );

  if (calculatedPH < 0.0) {
    calculatedPH = 0.0;
  }

  if (calculatedPH > 14.0) {
    calculatedPH = 14.0;
  }

  return calculatedPH;
}

// =====================================================
// EC CALCULATION
// =====================================================

double calculateEC(
  double voltage,
  double temperature
) {
  if (
    isnan(voltage) ||
    isnan(temperature)
  ) {
    return NAN;
  }

  double compensation =
    1.0 +
    EC_TEMPERATURE_COEFFICIENT *
    (temperature - 25.0);

  if (compensation <= 0.0) {
    Serial.println(
      "[EC] Invalid temperature compensation."
    );

    return NAN;
  }

  double voltageAt25C =
    voltage / compensation;

  double calculatedEC =
    (EC_SLOPE * voltageAt25C) +
    EC_INTERCEPT;

  if (calculatedEC < 0.0) {
    calculatedEC = 0.0;
  }

  if (CALIBRATION_MODE) {
    Serial.printf(
      "[EC CAL] Voltage normalized to 25 C: %.6f V\n",
      voltageAt25C
    );

    Serial.printf(
      "[EC CAL] Slope: %.6f | Intercept: %.6f\n",
      EC_SLOPE,
      EC_INTERCEPT
    );
  }

  return calculatedEC;
}

// =====================================================
// SAMPLE BUFFER
// =====================================================

void storeCompleteSample() {
  if (
    historySampleCount >=
    MAX_HISTORY_SAMPLES
  ) {
    Serial.println(
      "[BUFFER] Full; waiting for upload retry."
    );

    return;
  }

  phSamples[historySampleCount] =
    latestPH;

  ecSamples[historySampleCount] =
    latestEC;

  temperatureSamples[historySampleCount] =
    latestTemperature;

  historySampleCount++;

  Serial.printf(
    "[BUFFER] Complete samples: %d/~30\n",
    historySampleCount
  );
}

void resetHistoryBuffer() {
  historySampleCount = 0;
}

// =====================================================
// FIVE-MINUTE SNAPSHOT
// =====================================================

void processFiveMinuteHistory() {
  Serial.println();
  Serial.println("========================================");
  Serial.println("FIVE-MINUTE SNAPSHOT");
  Serial.println("========================================");

  if (historySampleCount <= 0) {
    Serial.println(
      "[HISTORY] No complete samples available."
    );

    return;
  }

  double averagePH =
    calculateMean(
      phSamples,
      historySampleCount
    );

  double medianPH =
    calculateMedian(
      phSamples,
      historySampleCount
    );

  double minimumPH =
    calculateMinimum(
      phSamples,
      historySampleCount
    );

  double maximumPH =
    calculateMaximum(
      phSamples,
      historySampleCount
    );

  double standardDeviationPH =
    calculateStandardDeviation(
      phSamples,
      historySampleCount,
      averagePH
    );

  double averageEC =
    calculateMean(
      ecSamples,
      historySampleCount
    );

  double medianEC =
    calculateMedian(
      ecSamples,
      historySampleCount
    );

  double minimumEC =
    calculateMinimum(
      ecSamples,
      historySampleCount
    );

  double maximumEC =
    calculateMaximum(
      ecSamples,
      historySampleCount
    );

  double standardDeviationEC =
    calculateStandardDeviation(
      ecSamples,
      historySampleCount,
      averageEC
    );

  double averageTemperature =
    calculateMean(
      temperatureSamples,
      historySampleCount
    );

  double medianTemperature =
    calculateMedian(
      temperatureSamples,
      historySampleCount
    );

  double minimumTemperature =
    calculateMinimum(
      temperatureSamples,
      historySampleCount
    );

  double maximumTemperature =
    calculateMaximum(
      temperatureSamples,
      historySampleCount
    );

  double standardDeviationTemperature =
    calculateStandardDeviation(
      temperatureSamples,
      historySampleCount,
      averageTemperature
    );

  Serial.printf(
    "[HISTORY] pH avg/median: %.4f / %.4f\n",
    averagePH,
    medianPH
  );

  Serial.printf(
    "[HISTORY] pH min/max/std: %.4f / %.4f / %.6f\n",
    minimumPH,
    maximumPH,
    standardDeviationPH
  );

  Serial.printf(
    "[HISTORY] EC avg/median: %.4f / %.4f\n",
    averageEC,
    medianEC
  );

  Serial.printf(
    "[HISTORY] EC min/max/std: %.4f / %.4f / %.6f\n",
    minimumEC,
    maximumEC,
    standardDeviationEC
  );

  Serial.printf(
    "[HISTORY] Temp avg/median: %.2f / %.2f C\n",
    averageTemperature,
    medianTemperature
  );

  Serial.printf(
    "[HISTORY] Temp min/max/std: %.2f / %.2f / %.4f\n",
    minimumTemperature,
    maximumTemperature,
    standardDeviationTemperature
  );

  Serial.printf(
    "[HISTORY] Sample count: %d\n",
    historySampleCount
  );

  bool uploaded = sendHistoryToSupabase(
    averagePH,
    medianPH,
    minimumPH,
    maximumPH,
    latestPH,
    standardDeviationPH,

    averageEC,
    medianEC,
    minimumEC,
    maximumEC,
    latestEC,
    standardDeviationEC,

    averageTemperature,
    medianTemperature,
    minimumTemperature,
    maximumTemperature,
    latestTemperature,
    standardDeviationTemperature,

    historySampleCount
  );

  if (uploaded) {
    resetHistoryBuffer();

    Serial.println(
      "[HISTORY] Upload complete; buffer reset."
    );
  } else {
    Serial.println(
      "[HISTORY] Upload failed; buffer retained."
    );
  }

  Serial.println("========================================");
}

// =====================================================
// STATISTICS
// =====================================================

double calculateMean(
  const double values[],
  int count
) {
  if (count <= 0) {
    return NAN;
  }

  double total = 0.0;

  for (int index = 0; index < count; index++) {
    total += values[index];
  }

  return total / (double)count;
}

double calculateMinimum(
  const double values[],
  int count
) {
  if (count <= 0) {
    return NAN;
  }

  double minimumValue = values[0];

  for (int index = 1; index < count; index++) {
    if (values[index] < minimumValue) {
      minimumValue = values[index];
    }
  }

  return minimumValue;
}

double calculateMaximum(
  const double values[],
  int count
) {
  if (count <= 0) {
    return NAN;
  }

  double maximumValue = values[0];

  for (int index = 1; index < count; index++) {
    if (values[index] > maximumValue) {
      maximumValue = values[index];
    }
  }

  return maximumValue;
}

double calculateMedian(
  const double values[],
  int count
) {
  if (
    count <= 0 ||
    count > MAX_HISTORY_SAMPLES
  ) {
    return NAN;
  }

  double sortedValues[MAX_HISTORY_SAMPLES];

  for (int index = 0; index < count; index++) {
    sortedValues[index] = values[index];
  }

  for (int index = 1; index < count; index++) {
    double currentValue =
      sortedValues[index];

    int previousIndex = index - 1;

    while (
      previousIndex >= 0 &&
      sortedValues[previousIndex] >
        currentValue
    ) {
      sortedValues[previousIndex + 1] =
        sortedValues[previousIndex];

      previousIndex--;
    }

    sortedValues[previousIndex + 1] =
      currentValue;
  }

  if (count % 2 == 0) {
    return (
      sortedValues[(count / 2) - 1] +
      sortedValues[count / 2]
    ) / 2.0;
  }

  return sortedValues[count / 2];
}

double calculateStandardDeviation(
  const double values[],
  int count,
  double mean
) {
  if (count <= 1) {
    return 0.0;
  }

  double total = 0.0;

  for (int index = 0; index < count; index++) {
    double difference =
      values[index] - mean;

    total += difference * difference;
  }

  return sqrt(
    total / (double)count
  );
}

// =====================================================
// SUPABASE UPLOAD
// =====================================================

bool sendHistoryToSupabase(
  double averagePH,
  double medianPH,
  double minimumPH,
  double maximumPH,
  double latestPHValue,
  double standardDeviationPH,

  double averageEC,
  double medianEC,
  double minimumEC,
  double maximumEC,
  double latestECValue,
  double standardDeviationEC,

  double averageTemperature,
  double medianTemperature,
  double minimumTemperature,
  double maximumTemperature,
  double latestTemperatureValue,
  double standardDeviationTemperature,

  int sampleCount
) {
  if (CALIBRATION_MODE) {
    Serial.println(
      "[HISTORY] Upload blocked by calibration mode."
    );

    return false;
  }

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(
      "[HISTORY] Wi-Fi unavailable."
    );

    return false;
  }

  String endpoint =
    String(SUPABASE_REST_URL) +
    "sensor_history";

  HTTPClient http;

  if (!http.begin(endpoint)) {
    Serial.println(
      "[HISTORY] HTTP initialization failed."
    );

    return false;
  }

  http.setTimeout(15000);

  http.addHeader(
    "apikey",
    SUPABASE_PUBLISHABLE_KEY
  );

  http.addHeader(
    "Authorization",
    "Bearer " +
    String(SUPABASE_PUBLISHABLE_KEY)
  );

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  http.addHeader(
    "Prefer",
    "return=minimal"
  );

  char json[1024];

  int jsonLength = snprintf(
    json,
    sizeof(json),

    "{"
      "\"avg_ph\":%.6f,"
      "\"median_ph\":%.6f,"
      "\"min_ph\":%.6f,"
      "\"max_ph\":%.6f,"
      "\"latest_ph\":%.6f,"
      "\"std_ph\":%.6f,"

      "\"avg_ec\":%.6f,"
      "\"median_ec\":%.6f,"
      "\"min_ec\":%.6f,"
      "\"max_ec\":%.6f,"
      "\"latest_ec\":%.6f,"
      "\"std_ec\":%.6f,"

      "\"avg_temp\":%.6f,"
      "\"median_temp\":%.6f,"
      "\"min_temp\":%.6f,"
      "\"max_temp\":%.6f,"
      "\"latest_temp\":%.6f,"
      "\"std_temp\":%.6f,"

      "\"sample_count\":%d"
    "}",

    averagePH,
    medianPH,
    minimumPH,
    maximumPH,
    latestPHValue,
    standardDeviationPH,

    averageEC,
    medianEC,
    minimumEC,
    maximumEC,
    latestECValue,
    standardDeviationEC,

    averageTemperature,
    medianTemperature,
    minimumTemperature,
    maximumTemperature,
    latestTemperatureValue,
    standardDeviationTemperature,

    sampleCount
  );

  if (
    jsonLength < 0 ||
    jsonLength >= (int)sizeof(json)
  ) {
    Serial.println(
      "[HISTORY] JSON buffer too small."
    );

    http.end();
    return false;
  }

  Serial.println("[HISTORY] Upload JSON:");
  Serial.println(json);

  int httpCode = http.POST(
    reinterpret_cast<uint8_t*>(json),
    strlen(json)
  );

  bool successful =
    httpCode >= 200 &&
    httpCode < 300;

  if (successful) {
    Serial.printf(
      "[HISTORY] Saved. HTTP %d\n",
      httpCode
    );
  } else {
    Serial.printf(
      "[HISTORY] Failed. HTTP %d\n",
      httpCode
    );

    if (httpCode > 0) {
      Serial.println(http.getString());
    }
  }

  http.end();
  return successful;
}

// =====================================================
// OLED
// =====================================================

void updateOLED() {
  if (!oledReady) {
    return;
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  display.setCursor(0, 0);
  display.print("pH: ");

  if (isnan(latestPH)) {
    display.print("--");
  } else {
    display.print(latestPH, 2);
  }

  display.setCursor(0, 15);
  display.print("EC: ");

  if (isnan(latestEC)) {
    display.print("--");
  } else {
    display.print(latestEC, 2);
    display.print(" mS");
  }

  display.setCursor(0, 30);
  display.print("Temp: ");

  if (isnan(latestTemperature)) {
    display.print("--");
  } else {
    display.print(latestTemperature, 1);
    display.print(" C");
  }

  display.setCursor(0, 45);

  if (CALIBRATION_MODE) {
    display.print("CAL MODE");
  } else {
    display.print("Samples:");
    display.print(historySampleCount);
    display.print("/30");
  }

  display.setCursor(94, 45);

  if (WiFi.status() == WL_CONNECTED) {
    display.print("WiFi");
  } else {
    display.print("OFF");
  }

  display.display();
}

