# Smart Helmet Companion Mobile App (`app`)

Cross-platform Flutter mobile application designed for riders and fleet operators, matching Google Stitch specifications with dark mode `#0F131C` aesthetics, Bluetooth Low Energy (BLE) hardware provisioning, real-time telemetry streaming, and local-network direct fallback.

---

## App Screens & Workflows

1. **Live Telemetry Cockpit (`screens/home_cockpit_screen.dart`)**:
   - Dual-Factor Ignition Interlock hero status (`LOCKED`, `UNLOCKED`, `RUNNING_LATCHED`).
   - Anti-Stall latch notification (safely preserving engine operation mid-ride).
   - Real-time speedometer (km/h) and 6-axis kinematics (Impact Gs, Tilt Angle).
   - Helmet wear detection indicator (FC-51 IR sensor).
   - Breathalyzer BAC gauge with quick-retest modal trigger.
   - Helmet 1S2P Li-ion battery health & voltage monitor.

2. **Bluetooth LE Provisioning Flow (`screens/ble_pairing_screen.dart`)**:
   - Scan for `SH-HLM-PROV` and `SH-IGN-PROV` GATT advertising beacons.
   - Signal strength RSSI indicator.
   - Dispatch WiFi credentials and 256-bit symmetric pairing PSK to hardware NVS over GATT characteristics.

3. **Pre-Ride Safety Check Sequence (`screens/pre_ride_check_screen.dart`)**:
   - 5-Point Safety Gate visual audit checklist.
   - Unlocks ignition circuit when all 5 conditions evaluate to TRUE.

4. **Trip & Ride History (`screens/ride_history_screen.dart`)**:
   - Trip duration, route distance, average velocity, and safety compliance score.

5. **Incident Alerts & Emergency SOS (`screens/alerts_screen.dart`)**:
   - Incident audit log with severity breakdown (`CRITICAL`, `HIGH`, `MEDIUM`).
   - GPS coordinate deep-linking for emergency dispatch.

6. **Breathalyzer Retest Flow (`screens/breathalyzer_modal.dart`)**:
   - Exhale pressure bar and countdown timer with real-time BAC evaluation.

7. **Emergency Contacts Management (`screens/contacts_screen.dart`)**:
   - Direct synchronization to hardware SIM800L flash storage.

8. **Rider Profile & Threshold Settings (`screens/settings_screen.dart`)**:
   - Configurable BAC threshold slider, accident impact G sensitivity, and temporary mechanic override.

---

## Running the App

```bash
# Get dependencies
flutter pub get

# Static code analysis
flutter analyze

# Run unit & widget tests
flutter test

# Run app on connected device / emulator
flutter run
```
