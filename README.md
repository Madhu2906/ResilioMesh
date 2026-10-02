# 🚨 ResilioMesh

**ResilioMesh** is an enterprise-grade, real-time Disaster Management and Emergency SOS platform engineered to provide reliable distress communication and rapid emergency dispatch during critical events.

The system combines a cross-platform **Flutter** mobile client for affected individuals, a scalable **Java Spring Boot** backend backed by a **PostgreSQL** database managed via **pgAdmin**, and an interactive **Web Admin Dashboard** for emergency control centers.

---

## 🌟 Key Capabilities

### 📱 Mobile Application (Flutter)
* **One-Tap Emergency SOS**: Triggers instant distress signals with built-in safety countdowns to eliminate false alarms (`sos_screen.dart`).
* **Voice Dictation Module**: Integrates hands-free speech-to-text functionality (`voice_dictation_widget.dart`) to transcribe real-time emergency descriptions directly into the distress payload.
* **Live Rescue & ETA Tracking**: Provides users with interactive visual tracking and active updates on dispatch team status (`eta_tracking_widget.dart`).
* **Situational Awareness Hub**: Features live geospatial disaster mapping (`disaster_map_screen.dart`), real-time weather monitoring (`live_weather_screen.dart`), and safety guides (`safety_tips_screen.dart`).
* **Offline Fallback Protocol**: Automatically reverts to direct SMS broadcasting with embedded coordinates when cellular data or backend connections are unavailable (`emergency_sms_contacts_screen.dart`).

### ⚙️ Backend & Database Services (Spring Boot & PostgreSQL)
* **RESTful Alert Pipeline**: Modular controllers (`SosController.java`, `AdminAlertController.java`) managing incoming distress signals, user session tracking, and admin actions.
* **Firebase Cloud Messaging (FCM)**: Custom integration (`FcmService.java`) delivering low-latency, real-time push notifications across dispatch consoles and mobile devices.
* **PostgreSQL Persistence**: Robust relational database architecture managed via pgAdmin, utilizing Spring Data JPA (`SosAlertRepository.java`, `UserRepository.java`) for ACID-compliant storage of distress entities, logs, and user profiles.

### 💻 Command & Control Center
* **Admin Dashboard (`admin_dashboard.html`)**: Web-based dispatch interface enabling operators to monitor live incoming alerts, verify locations, assign response units, and broadcast ETAs.

---

## 🏗️ Repository Architecture

```text
FINAL_PROJECT_2026/
├── ResilioMesh/                        # Flutter Client App
│   ├── lib/
│   │   ├── config/                     # Endpoint & network configurations (api_config.dart)
│   │   ├── services/                   # Authentication & device location handlers
│   │   ├── widgets/                    # Reusable components (ETA Tracking, Voice Dictation)
│   │   └── *_screen.dart               # Core UI screens (SOS, Maps, Weather, Profile)
│   └── pubspec.yaml
│
└── resiliomesh-backend/                # Java Spring Boot Server
    └── src/main/
        ├── java/com/resiliomesh/
        │   ├── config/                 # Firebase & security initializations
        │   ├── controller/             # Admin, Alert, SOS, & User endpoints
        │   ├── dto/                    # Request/Response Data Transfer Objects
        │   ├── entity/                 # Database entities (SosAlert, User)
        │   ├── repository/             # JPA Repositories
        │   └── service/                # Alert routing & FCM Push services
        └── resources/
            ├── application.properties  # PostgreSQL database connection configuration
            └── static/
                └── admin_dashboard.html # Web Dispatcher Dashboard

```
---

## 🛠️ Technology Stack

| Layer | Technologies Used |
| :--- | :--- |
| **Mobile Frontend** | Flutter, Dart |
| **Backend Framework** | Java 17+, Spring Boot, Spring Data JPA |
| **Database & Management** | PostgreSQL, pgAdmin |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Web Admin Interface** | HTML5, JavaScript, CSS3 |

---

## 🚀 Setup & Installation

### Prerequisites
* **Flutter SDK** (v3.0+)
* **JDK 17** or higher
* **PostgreSQL Server & pgAdmin**
* **Maven** (wrapper included)

---

### 1. Database Configuration (PostgreSQL & pgAdmin)

1. Open **pgAdmin** and create a new database named `resiliomesh_db`.
2. Set `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` as environment variables before starting the backend. Do not put credentials in the repository. Enable the PostGIS extension in the database (`CREATE EXTENSION postgis;`).

```properties
DB_URL=jdbc:postgresql://localhost:5432/resilio_db
DB_USERNAME=YOUR_POSTGRES_USERNAME
DB_PASSWORD=YOUR_POSTGRES_PASSWORD
```

### Firebase backend credentials and admin access

Configure Application Default Credentials with a Firebase service account outside the repository, for example by setting `GOOGLE_APPLICATION_CREDENTIALS` to the downloaded JSON file. Never commit that file. In PowerShell, set `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, and `GOOGLE_APPLICATION_CREDENTIALS` in the environment before launching the backend. The backend verifies Firebase ID tokens on every `/api/**` request. Users must be signed in; dispatch, alert listing, broadcasts, and legacy admin routes additionally require the Firebase custom claim `admin: true`. Set that claim only for trusted operator accounts using a trusted Firebase Admin SDK script or service. The admin dashboard signs in with Firebase email/password and refreshes the ID token automatically. Enable Email/Password sign-in, register a Firebase Web app, use its web SDK config in `admin_dashboard.html`, and add `localhost` (and the deployed dashboard host) to Firebase Authentication's authorized domains.

The previously committed database password and client API keys must be rotated in their provider consoles. Flutter no longer embeds the Gemini or OpenWeather keys; provide `GEMINI_API_KEY` and `OPENWEATHER_API_KEY` at build time with `--dart-define`. Client build-time keys are extractable from the app, so restrict them to the required APIs and use a server-side proxy for production-sensitive keys.

SOS requests may omit coordinates when location permission or GPS is unavailable. The dashboard then displays location as unavailable rather than sending responders to a fabricated default location.

2. Backend Service Setup
Navigate to the backend module:

```
Bash
cd resiliomesh-backend/resiliomesh-backend
```
