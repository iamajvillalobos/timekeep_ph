# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimekeepPh is a Rails 8.0 application using:
- Ruby on Rails 8.0.2
- PostgreSQL database
- Tailwind CSS for styling
- Stimulus & Turbo (Hotwire) for JavaScript
- Solid Cache, Solid Queue, and Solid Cable for data persistence
- Kamal for deployment with Docker

## Development Commands

### Server & Development
- `bin/dev` - Start development server with Foreman (includes Rails server + Tailwind watcher)
- `bin/rails server` - Start Rails server only
- `bin/rails tailwindcss:watch` - Watch and compile Tailwind CSS

### Code Quality & Testing
- `bin/rails test` - Run all tests
- `bin/rails test test/models/example_test.rb` - Run single test file
- `bin/rubocop` - Run RuboCop linter (uses rails-omakase config)
- `bin/brakeman` - Run security analysis

### Database
- `bin/rails db:create` - Create database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database
- `bin/rails db:setup` - Create, migrate, and seed database

### Asset Pipeline
- `bin/rails assets:precompile` - Precompile assets for production
- `bin/importmap` - Manage JavaScript imports

### Console & Debugging
- `bin/rails console` - Rails console
- `bin/rails dbconsole` - Database console

### Deployment (Kamal)
- `bin/kamal deploy` - Deploy application
- `bin/kamal console` - Remote Rails console
- `bin/kamal shell` - Remote shell access
- `bin/kamal logs` - View application logs

## Architecture

### Core Structure
- **Rails Application**: `TimekeepPh::Application` module in `config/application.rb`
- **Database**: PostgreSQL with Solid adapters for caching, queuing, and cable
- **Frontend**: Rails with Stimulus controllers, Turbo, and Tailwind CSS
- **Testing**: Minitest with parallel execution and system tests using Capybara/Selenium

### Data Models (Phase 1 - Complete)
- **Account**: Multi-tenant foundation with subdomain-based identification (UUID primary key)
- **User**: Backend authentication with Devise, role-based access (admin/hr/manager) (UUID primary key)
- **Branch**: Physical locations with multi-tenant scoping (UUID primary key)
- **Employee**: Workers with PIN authentication and cross-account validation (UUID primary key)
- **ClockEntry**: Time records with GPS coordinates, selfie URLs, and offline sync tracking (UUID primary key)

### Key Configuration Files
- `config/routes.rb` - Application routes (root, devise, employee auth, clock-in)
- `config/database.yml` - Database configuration
- `config/deploy.yml` - Kamal deployment configuration
- `config/application.rb` - Multi-tenant middleware configuration
- `Procfile.dev` - Development processes (web server + CSS watcher)
- `.rubocop.yml` - Code style configuration (inherits from rails-omakase)
- `db/seeds.rb` - Demo data for 3 companies with users, branches, and employees
- `app/controllers/clock_in_controller.rb` - Selfie clock-in with camera/GPS functionality
- `app/javascript/controllers/clock_in_controller.js` - Stimulus controller for camera/GPS capture

### Asset Pipeline
- Uses Propshaft for asset pipeline
- Tailwind CSS compilation via `railties`
- JavaScript managed through Import Maps
- Stimulus controllers in `app/javascript/controllers/`

### Job Processing
- Solid Queue configured to run in Puma process (`SOLID_QUEUE_IN_PUMA: true`)
- Jobs defined in `app/jobs/` inheriting from `ApplicationJob`

### Testing Structure
- Model tests: `test/models/`
- Controller tests: `test/controllers/`
- System tests: `test/system/`
- Integration tests: `test/integration/`
- Test helpers: `test/helpers/`
- Fixtures: `test/fixtures/`

## Development Guidelines

### Rails API Reference
- **ALWAYS use the latest Rails 8.0 methods** from https://api.rubyonrails.org/
- Reference the official API docs for current syntax and best practices
- Prefer new Rails 8 features over legacy approaches

### Git Commit Standards
- **Use Conventional Commits format**: `type(scope): description`
- **Commit in workable chunks** - each commit should be a complete, testable unit
- **Never add Claude Code comments** - code should be self-documenting
- **ALWAYS run `bin/rubocop` before committing** - fix all style issues
- **ALWAYS run tests before committing** - ensure nothing is broken
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Example: `feat(models): add UUID primary key configuration`

### Sustainable Rails Practices
This project follows principles from "Sustainable Rails" by David Bryant Copeland (see `sustainable-rails.md`):

- **Boring Technology**: Prefer Rails conventions and well-established patterns
- **Business Logic**: Keep complex logic in service objects and form objects, not controllers/models
- **Database Design**: Use proper constraints, indexes, and validation at the database level
- **Testing**: Write focused unit tests and comprehensive system tests
- **Views**: Use ViewComponent for reusable UI components when complexity warrants
- **Jobs**: Use ActiveJob with Solid Queue for background processing
- **Security**: Follow Rails security best practices, use strong parameters, validate at multiple levels

### Multi-tenant Architecture Guidelines
- Always scope queries by `account_id` to prevent data leakage
- Use UUIDs for all public-facing IDs to prevent enumeration
- Implement proper authorization checks at controller level
- Test tenant isolation thoroughly

## Current Feature Implementation Status

### Multi-tenant Foundation ✅ COMPLETED
- [x] UUID primary keys configured
- [x] Account model (companies/organizations)
- [x] User model (HR/admin backend access)
- [x] Tenant scoping middleware (TenantScopeMiddleware + Current attributes)
- [x] Subdomain routing (acme-corp.localhost:3000, tech-startup.localhost:3000, etc.)

### Employee Management ✅ COMPLETED
- [x] Branch model (physical locations)
- [x] Employee model (workers)
- [x] Employee authentication system (PIN-based with tenant isolation)

### Clock-in System (User Story U1) 
- [x] ClockEntry model
- [x] Clock-in controller with camera/GPS
- [x] Selfie capture with branch locking
- [x] Clock-in views with mobile-optimized interface
- [x] GPS location capture and validation
- [x] AJAX form submission with proper error handling
- [ ] Offline storage (IndexedDB)
- [ ] Auto-sync functionality

### Service Objects
- [ ] `ClockInService` - Handles camera, GPS, validation
- [ ] `OfflineSyncService` - Local storage and sync
- [x] `TenantService` - Account scoping (implemented via TenantScopeMiddleware)

### Security & Authorization ✅ COMPLETED
- [x] Devise authentication for Users (backend access)
- [x] Employee PIN-based identification (frontend worker access)
- [x] Tenant isolation validation (middleware enforces account boundaries)
- [x] Strong parameters and validation (comprehensive model validations)

## Maintenance Instructions

**IMPORTANT**: When adding new features, models, controllers, or significant changes:

1. **Update the Architecture section** with new components
2. **Add new models/controllers** to the relevant sections
3. **Update Feature Implementation Status** checkboxes
4. **Add new commands** to Development Commands if needed
5. **Document new service objects** in the guidelines
6. **Update routes** in Key Configuration Files when changed

This ensures CLAUDE.md stays current and useful for future development sessions.

## Demo Data & Testing

### Demo Accounts Available
Run `bin/rails db:seed` to create sample data:

1. **Acme Corporation** (`acme-corp`)
   - Admin: admin@acme-corp.com / password123
   - HR: hr@acme-corp.com / password123
   - Employees: EMP001 (PIN: 1234), EMP002 (PIN: 5678), EMP003 (PIN: 9999)

2. **Tech Startup Inc** (`tech-startup`)
   - Admin: admin@tech-startup.com / password123
   - Employees: DEV001 (PIN: 4321), DEV002 (PIN: 2468)

3. **Retail Chain LLC** (`retail-chain`)
   - Manager: manager@retail-chain.com / password123
   - Employees: RET001 (PIN: 1111), RET002 (PIN: 3333)

### Testing Multi-tenancy Locally
Use subdomain URLs to test tenant isolation:
- `acme-corp.localhost:3000` - Acme Corporation tenant
- `tech-startup.localhost:3000` - Tech Startup tenant  
- `retail-chain.localhost:3000` - Retail Chain tenant
- `localhost:3000` - Main application (no tenant)

### Authentication Testing
- **Backend Access**: Visit root URL (redirects to sign-in if not authenticated)
- **Employee Access**: Visit `/employee/login` on any tenant subdomain
- **Tenant Isolation**: Users/employees from one tenant cannot access another tenant's data