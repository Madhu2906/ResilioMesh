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
2. Configure your database credentials inside `resiliomesh-backend/resiliomesh-backend/src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/resiliomesh_db
spring.datasource.username=YOUR_POSTGRES_USERNAME
spring.datasource.password=YOUR_POSTGRES_PASSWORD
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

2. Backend Service Setup
Navigate to the backend module:

```
Bash
cd resiliomesh-backend/resiliomesh-backend
```
