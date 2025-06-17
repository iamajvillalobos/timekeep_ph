# TimekeepPh - Selfie Clock-in Implementation Progress

## User Story: U1 - Selfie clock-in (offline capable)
**Description**: As an Employee I can clock in/out with a selfie + GPS even when my phone is offline, so HR always gets authentic timestamps.

## System Architecture (Multi-tenant SaaS)

### Multi-tenancy Strategy
- **Single Database + Tenant ID**: One database with `account_id` on all tenant-specific tables
- **Subdomain-based**: `acme-corp.timekeep.com` identifies tenant, filters data by `account_id`
- **UUIDs**: All models use UUIDs as primary keys for security (prevents URL enumeration)

### Data Models
```
Account (Company/Organization) - UUID primary key
├── Users (Backend access - HR, Admins, Managers) - scoped by account_id
├── Branches (Physical locations) - scoped by account_id  
└── Employees (Workers who clock in/out) - scoped by account_id
    └── ClockEntries (Time records with photos/GPS) - scoped through employee
```

### Acceptance Criteria
- [x] Camera opens and captures a selfie
- [x] GPS lat/long is captured
- [x] Branch selector is locked after selfie
- [x] If offline, entry is stored locally and auto-syncs within 60s of connection

## Implementation Status

### Phase 1: Database Models & Migrations
- [ ] Configure Rails to use UUIDs as primary keys
- [ ] Account model (with subdomain for tenant identification)
- [ ] User model (with authentication, scoped by account_id)
- [ ] Branch model (scoped by account_id)
- [ ] Employee model (scoped by account_id)
- [ ] ClockEntry model (scoped through employee)

### Phase 2: Authentication & Authorization
- [ ] User authentication system
- [ ] Employee identification system
- [ ] Multi-tenant account scoping

### Phase 3: Clock-in Controller & Views
- [ ] Clock-in controller with camera/GPS
- [ ] Clock-in view with camera interface
- [ ] Branch selector component

### Phase 4: Offline Functionality
- [ ] IndexedDB storage via Stimulus
- [ ] Auto-sync mechanism
- [ ] Connection status detection

### Phase 5: Routes & Testing
- [ ] Clock-in routes
- [ ] Tests for all functionality

## Development Approach (Following Sustainable Rails)

### Core Principles Applied
- **Database-First Design**: Proper constraints, indexes, foreign keys at DB level
- **Service Objects**: Complex business logic (clock-in/sync) moved to service classes
- **Form Objects**: Clock-in form handling separated from models
- **Boring Technology**: Standard Rails patterns, avoid over-engineering
- **Security**: Multiple validation layers, strong parameters, tenant isolation

### Key Service Objects Needed
- `ClockInService` - Handles selfie capture, GPS, branch validation
- `OfflineSyncService` - Manages local storage and background sync
- `TenantService` - Account scoping and subdomain resolution

## Next Steps
Starting with UUID configuration and Account model creation...

## Models Schema Design

### Account
```ruby
# Multi-tenant company/organization (UUID primary key)
class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :branches, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :clock_entries, through: :employees
  
  # Rails 8 attribute normalization
  normalize_attribute :subdomain, with: -> subdomain { subdomain.strip.downcase }
  normalize_attribute :name, with: -> name { name.strip }
  
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
end
```

### User
```ruby
# Backend access (HR, Admins, Managers) - UUID primary key
class User < ApplicationRecord
  belongs_to :account
  
  # Rails 8 attribute normalization
  normalize_attribute :email, with: -> email { email.strip.downcase }
  normalize_attribute :name, with: -> name { name.strip }
  
  # Will use Devise for authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  enum role: { admin: 0, hr: 1, manager: 2 }
  
  validates :email, presence: true, uniqueness: { scope: :account_id }
  validates :role, presence: true
  
  # Scope all queries to account
  scope :for_account, ->(account) { where(account: account) }
end
```

### Branch
```ruby
# Physical locations where employees work - UUID primary key
class Branch < ApplicationRecord
  belongs_to :account
  has_many :employees, dependent: :destroy
  has_many :clock_entries, dependent: :destroy
  
  validates :name, presence: true
  validates :address, presence: true
  
  scope :active, -> { where(active: true) }
  scope :for_account, ->(account) { where(account: account) }
end
```

### Employee
```ruby
# Workers who clock in/out - UUID primary key
class Employee < ApplicationRecord
  belongs_to :account
  belongs_to :branch
  has_many :clock_entries, dependent: :destroy
  
  # Rails 8 attribute normalization
  normalize_attribute :name, with: -> name { name.strip }
  normalize_attribute :email, with: -> email { email&.strip&.downcase }
  normalize_attribute :employee_id, with: -> id { id.strip.upcase }
  
  validates :name, presence: true
  validates :employee_id, presence: true, uniqueness: { scope: :account_id }
  validates :pin, presence: true, length: { minimum: 4 }
  
  scope :active, -> { where(active: true) }
  scope :for_account, ->(account) { where(account: account) }
  
  # Ensure branch belongs to same account
  validate :branch_belongs_to_account
  
  private
  
  def branch_belongs_to_account
    return unless branch && account
    errors.add(:branch, "must belong to the same account") if branch.account != account
  end
end
```

### ClockEntry
```ruby
# Time records with photos and GPS - UUID primary key
class ClockEntry < ApplicationRecord
  belongs_to :employee
  belongs_to :branch
  
  validates :employee_id, presence: true
  validates :branch_id, presence: true
  validates :gps_latitude, presence: true, numericality: { in: -90..90 }
  validates :gps_longitude, presence: true, numericality: { in: -180..180 }
  
  scope :pending_sync, -> { where(synced: false) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :for_account, ->(account) { joins(employee: :account).where(employees: { account: account }) }
  
  # Ensure employee and branch belong to same account
  validate :employee_and_branch_same_account
  
  private
  
  def employee_and_branch_same_account
    return unless employee && branch
    errors.add(:branch, "must belong to same account as employee") if employee.account != branch.account
  end
end
```