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

### Key Configuration Files
- `config/routes.rb` - Application routes (currently minimal with health check)
- `config/database.yml` - Database configuration
- `config/deploy.yml` - Kamal deployment configuration
- `Procfile.dev` - Development processes (web server + CSS watcher)
- `.rubocop.yml` - Code style configuration (inherits from rails-omakase)

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