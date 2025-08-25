# FitTech - REST API for Fitness and Nutrition App

## Description
Implemented in Python's FastAPI framework and using a relational PostgreSQL database, this REST API provides the necessary functionalities for an app related with Fitness and Nutrition, handling authentication, database integration and HTTPS methods.
This application has been containerized using Docker. A Dockerfile is used to build the main REST API container, while a Docker Compose file orchestrates two containers: one for the REST API and another for the PostgreSQL database.

## Setup
To start the application, make sure you have Docker CLI installed and updated to the latest version and run the following command: 
```
docker-compose up
```

To stop the application:
```
docker-compose down
```

## Database entities
- Users: minimal user information
- Onboarding: physical and health data.
- Food-logs: 
- Workout-logs: 

## Methods
- POST auth/register: creates a new user.
- POST auth/token: login a user and provides a temporary JWT token.
- POST users/{user_id}/onboarding: uploads the user's onboarding data.
- GET users/{user_id}/onboarding: returns the user's onboarding data.
- PUT users/{user_id}/onboarding: updates the user's onboarding data.
- POST users/{user_id}/food-logs: uploads a food log.
- GET users/{user_id}/food-logs: returns all the user's food logs.
- POST users/{user_id}/workout-logs: uploads a workout log.
- GET users/{user_id}/workout-logs: returns all the user's workout logs.
- GET dashboard: returns a JSON with the user's BMR and TDEE metrics, macros requirements, the total calories, protein, carbs, and fat consumed, and all the food and workout logs from today.
