# TimekeepPh Customer Onboarding Process

## Overview

TimekeepPh uses a subdomain-based multi-tenant architecture where each customer gets their own dedicated URL (e.g., `acme-corp.timekeep.ph`). This requires a managed onboarding process rather than self-service signup.

## Infrastructure Setup

### DNS & SSL Configuration
- **Wildcard DNS**: `*.timekeep.ph` configured in Cloudflare
- **SSL Certificates**: Automatically managed by Cloudflare
- **No additional server setup required** for new customers

### Scalability
- **Database**: PostgreSQL automatically scales with new tenants
- **Application**: Single Rails app handles all tenants via middleware
- **Storage**: Shared infrastructure with tenant isolation

## Onboarding Workflow

### Step 1: Customer Information Collection

**Sales Team Collects:**
- Company/Organization name
- Desired subdomain (e.g., "acme-corp" for acme-corp.timekeep.ph)
- Primary admin contact name and email
- Number of expected employees (for planning)
- Business requirements (locations, special needs)

**Subdomain Requirements:**
- Must be unique across all customers
- Only lowercase letters, numbers, and hyphens
- 3-30 characters recommended
- Examples: `acme-corp`, `tech-startup`, `retail-chain`

### Step 2: Account Creation (Technical Team)

**Option A: Using Rake Task (Recommended)**
```bash
# Production
bin/kamal console "bin/rails onboarding:create_account['Acme Corporation','acme-corp','John Smith','john@acme-corp.com']"

# Development
bin/rails onboarding:create_account['Acme Corporation','acme-corp','John Smith','john@acme-corp.com']
```

**Option B: Rails Console (Advanced)**
```ruby
# See CLAUDE.md for manual console commands
account = Account.create!(name: "Company Name", subdomain: "subdomain", active: true)
# ... additional setup commands
```

**What Gets Created:**
- ✅ Company account with unique subdomain
- ✅ Admin user with secure temporary password
- ✅ Default "Main Office" branch (customer updates address later)
- ✅ Ready-to-use tenant environment

### Step 3: Credential Delivery

**Send to Customer (via secure channel):**
```
Welcome to TimekeepPh!

Your account has been created:
• Company: [Company Name]
• Login URL: https://[subdomain].timekeep.ph
• Admin Email: [admin@email.com]
• Temporary Password: [generated_password]

Next Steps:
1. Log in and change your password immediately
2. Update your branch address and information
3. Add your employees and set their PINs
4. Test the employee clock-in system

Employee Access:
Your employees will use: https://[subdomain].timekeep.ph/employee/login

Support: [support contact information]
```

### Step 4: Customer Self-Setup

**Customer Responsibilities:**
1. **Initial Login**: Change temporary password
2. **Company Setup**: 
   - Update default branch address
   - Add additional branches if needed
3. **Employee Management**:
   - Add employees with unique Employee IDs
   - Set secure 4+ digit PINs for each employee
   - Assign employees to appropriate branches
4. **Testing**: Verify employee clock-in functionality

## Account Management Commands

### List All Customers
```bash
bin/rails onboarding:list_accounts
```

### View Customer Details
```bash
bin/rails onboarding:show_account[acme-corp]
```

### Deactivate Customer
```bash
bin/rails onboarding:deactivate_account[acme-corp]
```

### Reactivate Customer
```bash
bin/rails onboarding:reactivate_account[acme-corp]
```

## Customer Success Checklist

### ✅ Day 1: Account Creation
- [ ] Collect customer information
- [ ] Create account using rake task
- [ ] Verify subdomain accessibility
- [ ] Send credentials via secure channel

### ✅ Day 2-3: Customer Setup
- [ ] Customer changes password
- [ ] Branch information updated
- [ ] First employees added
- [ ] Initial clock-in test completed

### ✅ Week 1: Full Deployment
- [ ] All employees onboarded
- [ ] Clock-in process working smoothly
- [ ] Any custom requirements addressed
- [ ] Customer training completed

## Troubleshooting

### Common Issues

**"Tenant not found" Error**
- Check subdomain spelling in URL
- Verify account is active: `Account.find_by(subdomain: "customer").active?`
- Check DNS propagation (rare with Cloudflare)

**Login Issues**
- Verify user email and account association
- Reset password via Rails console if needed
- Check account is active and matches subdomain

**Employee Clock-in Issues**
- Verify employee belongs to correct account
- Check branch is active and belongs to account
- Test GPS/camera permissions in browser

### Support Commands

**Check Account Status:**
```ruby
account = Account.find_by(subdomain: "customer")
puts "Active: #{account.active?}"
puts "Users: #{account.users.count}"
puts "Employees: #{account.employees.count}"
```

**Reset Admin Password:**
```ruby
user = User.find_by(email: "admin@customer.com")
new_password = SecureRandom.hex(8)
user.update!(password: new_password, password_confirmation: new_password)
puts "New password: #{new_password}"
```

## Security Considerations

### Tenant Isolation
- All data automatically scoped by `account_id`
- Middleware enforces subdomain-to-account mapping
- Users cannot access other tenants' data

### Password Management
- Temporary passwords auto-generated (16 characters)
- Customers must change password on first login
- Employee PINs are customer-managed

### Data Privacy
- Each tenant's data is logically separated
- No cross-tenant data leakage possible
- GPS and photo data tied to specific accounts

## Scaling Considerations

### Current Capacity
- **Single Rails application** handles all tenants
- **PostgreSQL** scales to thousands of tenants
- **Cloudflare CDN** handles global traffic

### Growth Planning
- Monitor database size and query performance
- Consider read replicas for high-traffic customers
- Plan for background job scaling (Solid Queue)

### Cost Structure
- **Infrastructure**: Shared across all tenants
- **Database**: Grows linearly with customer data
- **Bandwidth**: Scales with employee activity

## Customer Success Metrics

### Track These KPIs
- Time from account creation to first clock-in
- Customer adoption rate (employees using system)
- Support tickets per new customer
- Customer satisfaction with onboarding process

### Success Indicators
- ✅ Customer completes setup within 3 days
- ✅ 80%+ employee adoption within 1 week
- ✅ Zero critical support issues in first month
- ✅ Customer provides positive onboarding feedback