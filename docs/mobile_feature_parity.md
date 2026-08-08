# Mobile Feature Parity Tracker

Source references:
- Web app: https://proximity-driver-intelligence-app.prod-app.in/
- API spec: https://proximity-driver-api.prod-app.in/swagger/v1/swagger.json

## Current Mobile Coverage

### Already implemented in Flutter project
- Authentication:
  - POST /api/auth/login
- Fleet map:
  - GET /api/fleet-map/vehicles
  - GET /api/vehicle
- Incidents:
  - GET /api/incidents
  - Incident detail/review UI is present
- Scorecard:
  - GET /api/scorecard
- Master enrollment and registration workflows:
  - Driver and vehicle enrollment-related screens exist
- Configuration:
  - Vehicle Types CRUD + status:
    - GET/POST /api/vehicle-types
    - PUT /api/vehicle-types/{id}
    - PATCH or PUT /api/vehicle-types/{id}/status
  - Project Sites CRUD + status:
    - GET/POST /api/project-sites
    - PUT /api/project-sites/{id}
    - PATCH or PUT /api/project-sites/{id}/status

### Implemented in this update
- Admin management module:
  - GET /api/auth/admins
  - POST /api/auth/admins
  - PUT /api/auth/admins/{id}
  - DELETE /api/auth/admins/{id}
- Device management module:
  - GET /api/devices
  - POST /api/devices
  - PUT /api/devices/{id}
  - DELETE /api/devices/{id}
  - POST /api/devices/{id}/assign/{vehicleId}
  - POST /api/devices/{id}/unassign
- New Settings navigation entry:
  - Admins & Devices screen

## Remaining Work for Full Web Parity

### Priority 1
- Geofence management and violations:
  - GET/POST /api/geofences
  - GET/PUT/DELETE /api/geofences/{id}
  - GET /api/geofences/vehicle/{vehicleId}
  - POST /api/geofences/violation
  - GET /api/geofences/violations
- Incident alert settings:
  - GET/POST /api/settings/incident-alerts
  - PUT/DELETE /api/settings/incident-alerts/{id}
- Incident workflow completion:
  - PATCH /api/incidents/{id}/acknowledge
  - PATCH /api/incidents/{id}/resolve
  - GET /api/incidents/notifications
  - GET /api/incidents/event-types

### Priority 2
- Trip management:
  - POST /api/trips/start
  - POST /api/trips/end
  - GET /api/trips
  - GET /api/trips/{tripId}/points
- Video recordings:
  - GET /api/video-recordings
  - GET /api/video-recordings/vehicle/{vehicleId}
  - POST /api/video-recordings/upload
- App version and updates:
  - GET /api/app-version/latest
  - GET /api/app-version

### Priority 3
- System and edge features:
  - POST /api/telemetry/location
  - GET /api/tts/alert
  - POST /api/auth/setup and setup-needed
  - POST /api/devices/register

## Notes
- Some response schemas are not explicitly defined in Swagger components; mobile parsing currently uses defensive dynamic mapping in the new modules.
- Role-based screen gating should be added once role matrix is confirmed from production web behavior (Admin, Supervisor, Fleet Manager).
