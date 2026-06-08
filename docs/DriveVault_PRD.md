# Product Requirements Document (PRD)

## DriveVault — AI-Powered Vehicle Ownership Platform

*From first mile to resale.*

### Product Vision

DriveVault helps vehicle owners manage every aspect of vehicle ownership from a single mobile app.

Instead of manually tracking maintenance, expenses, insurance, registrations, fuel consumption, and repair history, users can simply upload receipts, take photos, and ask questions in natural language.

The app becomes the "source of truth" for a vehicle's lifecycle.

---

# 1. Problem Statement

Vehicle owners typically struggle with:

- Lost service records
- Forgotten maintenance schedules
- Untracked ownership costs
- Scattered invoices
- Insurance renewal surprises
- Poor resale documentation
- No centralized vehicle history

Most existing apps only solve one part of the problem:

- Fuel tracking
- Maintenance reminders
- Expense tracking

Few combine all ownership data with AI assistance.

---

# 2. Product Goals

### User Goals

- Know exactly when maintenance is due
- Track total ownership cost
- Never lose vehicle documents
- Quickly find service history
- Prepare vehicles for resale

### Business Goals

- Demonstrate:

  - Flutter expertise
  - AI integration
  - OCR processing
  - Full-stack architecture
  - Analytics
  - Offline-first design

Potential future SaaS opportunities:

- Premium subscriptions
- Fleet management
- Mechanic integrations
- Insurance partnerships

---

# 3. Target Users

## Primary

Vehicle owners with 1-3 vehicles.

Examples:

- Car owners
- Motorcycle owners
- Pickup owners

---

## Secondary

Vehicle enthusiasts.

Examples:

- Modified cars
- Project vehicles
- Collectors

---

## Future

Small fleet operators.

Examples:

- Delivery businesses
- Service companies
- Taxi operators

---

# MVP Roadmap

---

# PHASE 1

## Foundation MVP

Goal:

Create a useful vehicle management application without AI.

Estimated:
4-6 weeks

---

## Features

### Authentication

- Email login
- Google login
- Apple login

---

### Vehicle Management

Create vehicle:

- Make
- Model
- Year
- Registration Number
- VIN
- Purchase Date
- Current Mileage

Vehicle photo support.

---

### Maintenance Records

Add service entries:

- Date
- Mileage
- Service Type
- Cost
- Notes

Examples:

- Oil Change
- Brake Service
- Tire Rotation

---

### Fuel Tracking

Add fuel purchase:

- Date
- Liters
- Price
- Odometer

Automatically calculate:

- Fuel economy
- Cost per km
- Monthly spend

---

### Document Vault

Store:

- Registration
- Insurance
- Warranty
- Service documents

Cloud storage.

---

### Dashboard

Show:

- Next service
- Upcoming renewals
- Monthly fuel spend
- Total ownership cost

---

## Success Metrics

User can:

- Add vehicle
- Track fuel
- Add services
- Upload documents

without AI.

---

# PHASE 2

## Smart Ownership Features

Goal:

Automate maintenance management.

Estimated:
3-4 weeks

---

## Maintenance Scheduler

Create service intervals:

Example:

Oil Change

Every:

- 6 months
  OR
- 5000 km

---

### Automatic Reminders

Push notifications:

Examples:

- Insurance expires in 30 days
- Oil service due in 500 km

---

### Vehicle Timeline

Chronological history:

- Purchases
- Services
- Fuel
- Repairs

Like a social feed for vehicle ownership.

---

### Ownership Analytics

Graphs:

- Monthly expenses
- Fuel efficiency trends
- Maintenance costs

---

### Cost Analysis

Show:

Total Spend

Breakdown:

- Fuel
- Maintenance
- Insurance
- Registration

---

## Success Metrics

User gains value without entering AI chat.

---

# PHASE 3

## AI Document Intelligence

Goal:

Reduce manual data entry.

Estimated:
4-6 weeks

---

## Invoice Scanner

User uploads:

- Service invoice
- Receipt
- Workshop report

---

### OCR Processing

Extract:

- Date
- Workshop
- Parts
- Labor
- Cost

---

### AI Structuring

Convert invoice into:

Maintenance record.

Example:

Invoice Upload

↓

AI Output

Oil Change
Brake Fluid Replacement
Cost: $150

↓

One-click import

---

### Confidence System

Show:

90% confidence

User can edit before saving.

---

### Smart Categorization

Automatically identify:

- Maintenance
- Repair
- Upgrade
- Inspection

---

## Success Metrics

80%+ of invoice data extracted automatically.

---

# PHASE 4

## AI Vehicle Assistant

Goal:

Natural language interaction.

Estimated:
4-5 weeks

---

## Chat Assistant

Examples:

"What did I spend on maintenance this year?"

"When was my last oil change?"

"Which vehicle costs me more?"

---

## Tool Calling Architecture

AI does not use RAG initially.

Instead:

LLM
↓
Backend Tools
↓
SQL Queries

Example:

Question

↓

Tool Call

GetMaintenanceCost(
vehicleId,
dateRange
)

↓

Response

---

### Suggested Questions

Generate:

- Service recommendations
- Upcoming maintenance
- Cost summaries

---

### Voice Input

User speaks:

"When did I replace my tires?"

Receive answer.

---

## Success Metrics

Useful answers from structured data.

---

# PHASE 5

## Predictive Maintenance

Goal:

Create "wow factor".

Estimated:
4-6 weeks

---

## Service Forecasting

Predict:

- Tire replacement
- Brake replacement
- Battery replacement

based on:

- Mileage
- Vehicle age
- Service history

---

## Ownership Insights

Examples:

"Maintenance spending increased 32% this quarter."

"Fuel efficiency has dropped 12%."

"This vehicle may require brake servicing within 2 months."

---

## Health Score

Vehicle score:

0-100

Factors:

- Maintenance history
- Overdue services
- Vehicle age

---

## Resale Readiness Score

Based on:

- Complete records
- Service consistency
- Document availability

---

# PHASE 6

## RAG & Deep Knowledge

Goal:

Use AI where it truly adds value.

Estimated:
3-4 weeks

---

## Document Search

User asks:

"What brake pads were installed last year?"

Searches:

- Invoices
- Service reports
- Workshop notes

---

## Semantic Search

Find information even when wording differs.

Example:

"Suspension issue"

matches:

"Front lower control arm worn"

---

## Vehicle Knowledge Base

Upload:

- Owner manuals
- Service manuals
- Warranty documents

Ask:

"What oil grade does this vehicle require?"

---

## Hybrid Retrieval

Structured Queries

*

Vector Search

Combined into a single answer.

---

# Technical Architecture

## Mobile

Flutter

State Management:

- Riverpod

Offline Storage:

- Drift SQLite

Notifications:

- Firebase

---

## Backend

Possible options:

### Option A

Flutter + Supabase

Fastest MVP

---

### Option B

Flutter + FastAPI

More impressive architecture

Recommended for portfolio.

---

## Database

PostgreSQL

Tables:

- Users
- Vehicles
- Fuel Logs
- Maintenance Records
- Documents
- AI Extractions

---

## AI Stack

### Phase 3

OCR

- Gemini
- OpenAI
- Document AI

---

### Phase 4

Tool Calling

- Gemini
- GPT
- Claude

---

### Phase 6

RAG

- pgvector
- PostgreSQL

---

# Portfolio Demo Scenarios

When showcasing the project:

### Scenario 1

Upload invoice

↓

AI extracts maintenance

↓

Creates record

---

### Scenario 2

Ask:

"How much have I spent on this car this year?"

↓

AI answers with analytics

---

### Scenario 3

Show ownership dashboard

↓

Fuel trends

↓

Maintenance trends

↓

Predictions

---

# Why This Project Stands Out

Most portfolio apps demonstrate:

- CRUD
- Authentication
- Basic API integration

DriveVault demonstrates:

- Flutter
- Offline-first architecture
- OCR
- AI extraction
- Function calling
- Analytics
- Predictive insights
- RAG (later)
- Mobile + backend + AI system design

This is the kind of project that can realistically be presented as a production-ready SaaS rather than a demo app, which makes it much stronger for attracting clients and senior engineering opportunities.
