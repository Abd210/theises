# Project Overview & Why a Prayer App Fits the Thesis

## Thesis Title
Performance and Productivity Analysis of Contemporary Cross-Platform Mobile Development Technologies:
A Comparative Study of Flutter and React Native (Expo) using a Muslim Prayer App.

## Goal
Build the same Muslim prayer app twice:
- Implementation A: Flutter
- Implementation B: React Native (Expo)

Then evaluate and compare:
- Performance (runtime efficiency and user-perceived responsiveness)
- Productivity (development effort, change velocity, debugging effort)

## Research Question
How do Flutter and React Native (Expo) compare in performance and developer productivity when implementing a feature-identical real-world mobile application?

## Why a Muslim Prayer App is a Good Fit (Justification)
A Muslim prayer app is a strong case study because it represents a realistic mobile application that requires:

1. UI Rendering & Responsiveness
- Prayer timetable lists and frequent updates (countdown timer)
- Navigation between multiple screens
- Smooth scrolling and transitions

2. Platform Features & Permissions
- Location services (GPS permissions, accuracy, fallbacks)
- Notifications scheduling (background behavior differences across iOS/Android)

3. Sensor / Device Hardware Integration
- Compass / magnetometer use for Qibla direction
- Continuous sensor updates stress CPU and rendering smoothness

4. Background Work & Reliability
- Scheduling multiple time-based notifications daily
- Handling timezone changes and daylight saving changes

These features cover common cross-platform challenges and allow measuring performance and productivity in a controlled, repeatable way.

## Independent vs Dependent Variables
Independent Variable:
- Framework choice (Flutter vs React Native Expo)

Dependent Variables:
- Performance metrics: startup time, render time, FPS/jank, CPU/memory, energy impact, app size
- Productivity metrics: development time per feature, defects and fix time, change request time, build/iteration time

Control Variables (to ensure fairness)
- Same functional requirements and UX flow
- Same dataset / same prayer-time source and settings
- Same test devices (model + OS), same network conditions
- Measurements taken in Release/Profile (not Debug)
