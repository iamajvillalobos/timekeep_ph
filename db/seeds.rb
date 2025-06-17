# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# TimekeepPh Demo Data Seeder
# Creates sample accounts, users, branches, and employees for demonstration

puts "🌱 Seeding TimekeepPh demo data..."

# Create demo accounts (companies)
puts "Creating demo accounts..."

acme_corp = Account.find_or_create_by!(subdomain: "acme-corp") do |account|
  account.name = "Acme Corporation"
  account.active = true
end
puts "  ✓ #{acme_corp.name} (#{acme_corp.subdomain})"

tech_startup = Account.find_or_create_by!(subdomain: "tech-startup") do |account|
  account.name = "Tech Startup Inc"
  account.active = true
end
puts "  ✓ #{tech_startup.name} (#{tech_startup.subdomain})"

retail_chain = Account.find_or_create_by!(subdomain: "retail-chain") do |account|
  account.name = "Retail Chain LLC"
  account.active = true
end
puts "  ✓ #{retail_chain.name} (#{retail_chain.subdomain})"

# Create demo users (backend admin/HR access)
puts "Creating demo users..."

# Acme Corp Users
acme_admin = User.find_or_create_by!(email: "admin@acme-corp.com") do |user|
  user.name = "Alice Admin"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.account = acme_corp
end
puts "  ✓ #{acme_admin.name} (#{acme_admin.email}) - #{acme_admin.role}"

acme_hr = User.find_or_create_by!(email: "hr@acme-corp.com") do |user|
  user.name = "Bob HR Manager"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :hr
  user.account = acme_corp
end
puts "  ✓ #{acme_hr.name} (#{acme_hr.email}) - #{acme_hr.role}"

# Tech Startup Users
tech_admin = User.find_or_create_by!(email: "admin@tech-startup.com") do |user|
  user.name = "Carol Tech Admin"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.account = tech_startup
end
puts "  ✓ #{tech_admin.name} (#{tech_admin.email}) - #{tech_admin.role}"

# Retail Chain Users
retail_manager = User.find_or_create_by!(email: "manager@retail-chain.com") do |user|
  user.name = "David Store Manager"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :manager
  user.account = retail_chain
end
puts "  ✓ #{retail_manager.name} (#{retail_manager.email}) - #{retail_manager.role}"

# Create demo branches
puts "Creating demo branches..."

# Acme Corp Branches
acme_downtown = Branch.find_or_create_by!(name: "Downtown Office", account: acme_corp) do |branch|
  branch.address = "123 Main Street, Downtown, Metro City"
  branch.active = true
end
puts "  ✓ #{acme_downtown.name} - #{acme_corp.name}"

acme_uptown = Branch.find_or_create_by!(name: "Uptown Branch", account: acme_corp) do |branch|
  branch.address = "456 Uptown Ave, Uptown, Metro City"
  branch.active = true
end
puts "  ✓ #{acme_uptown.name} - #{acme_corp.name}"

# Tech Startup Branches
tech_main = Branch.find_or_create_by!(name: "Main Office", account: tech_startup) do |branch|
  branch.address = "789 Innovation Drive, Tech District"
  branch.active = true
end
puts "  ✓ #{tech_main.name} - #{tech_startup.name}"

# Retail Chain Branches
retail_mall = Branch.find_or_create_by!(name: "Mall Store", account: retail_chain) do |branch|
  branch.address = "100 Shopping Mall, Retail District"
  branch.active = true
end
puts "  ✓ #{retail_mall.name} - #{retail_chain.name}"

retail_outlet = Branch.find_or_create_by!(name: "Outlet Store", account: retail_chain) do |branch|
  branch.address = "200 Outlet Plaza, Commercial Zone"
  branch.active = true
end
puts "  ✓ #{retail_outlet.name} - #{retail_chain.name}"

# Create demo employees
puts "Creating demo employees..."

# Acme Corp Employees
acme_john = Employee.find_or_create_by!(employee_id: "EMP001", account: acme_corp) do |employee|
  employee.name = "John Smith"
  employee.email = "john.smith@acme-corp.com"
  employee.pin = "1234"
  employee.branch = acme_downtown
  employee.active = true
end
puts "  ✓ #{acme_john.name} (#{acme_john.employee_id}) - #{acme_downtown.name}"

acme_jane = Employee.find_or_create_by!(employee_id: "EMP002", account: acme_corp) do |employee|
  employee.name = "Jane Wilson"
  employee.email = "jane.wilson@acme-corp.com"
  employee.pin = "5678"
  employee.branch = acme_uptown
  employee.active = true
end
puts "  ✓ #{acme_jane.name} (#{acme_jane.employee_id}) - #{acme_uptown.name}"

acme_mike = Employee.find_or_create_by!(employee_id: "EMP003", account: acme_corp) do |employee|
  employee.name = "Mike Johnson"
  employee.email = "mike.johnson@acme-corp.com"
  employee.pin = "9999"
  employee.branch = acme_downtown
  employee.active = true
end
puts "  ✓ #{acme_mike.name} (#{acme_mike.employee_id}) - #{acme_downtown.name}"

# Tech Startup Employees
tech_bob = Employee.find_or_create_by!(employee_id: "DEV001", account: tech_startup) do |employee|
  employee.name = "Bob Developer"
  employee.email = "bob.dev@tech-startup.com"
  employee.pin = "4321"
  employee.branch = tech_main
  employee.active = true
end
puts "  ✓ #{tech_bob.name} (#{tech_bob.employee_id}) - #{tech_main.name}"

tech_sarah = Employee.find_or_create_by!(employee_id: "DEV002", account: tech_startup) do |employee|
  employee.name = "Sarah Designer"
  employee.email = "sarah.design@tech-startup.com"
  employee.pin = "2468"
  employee.branch = tech_main
  employee.active = true
end
puts "  ✓ #{tech_sarah.name} (#{tech_sarah.employee_id}) - #{tech_main.name}"

# Retail Chain Employees
retail_lisa = Employee.find_or_create_by!(employee_id: "RET001", account: retail_chain) do |employee|
  employee.name = "Lisa Cashier"
  employee.email = "lisa.cashier@retail-chain.com"
  employee.pin = "1111"
  employee.branch = retail_mall
  employee.active = true
end
puts "  ✓ #{retail_lisa.name} (#{retail_lisa.employee_id}) - #{retail_mall.name}"

retail_tom = Employee.find_or_create_by!(employee_id: "RET002", account: retail_chain) do |employee|
  employee.name = "Tom Sales"
  employee.email = "tom.sales@retail-chain.com"
  employee.pin = "3333"
  employee.branch = retail_outlet
  employee.active = true
end
puts "  ✓ #{retail_tom.name} (#{retail_tom.employee_id}) - #{retail_outlet.name}"

puts "\n🎉 Seeding completed successfully!"
puts "\n📋 Demo Data Summary:"
puts "  • #{Account.count} Accounts (Companies)"
puts "  • #{User.count} Users (Backend Access)"
puts "  • #{Branch.count} Branches (Locations)"
puts "  • #{Employee.count} Employees (Workers)"

puts "\n🔐 Demo Login Credentials:"
puts "\n  Backend Admin Access:"
puts "  • admin@acme-corp.com / password123 (Acme Corp Admin)"
puts "  • hr@acme-corp.com / password123 (Acme Corp HR)"
puts "  • admin@tech-startup.com / password123 (Tech Startup Admin)"
puts "  • manager@retail-chain.com / password123 (Retail Chain Manager)"

puts "\n  Employee PIN Access (use subdomains):"
puts "  • acme-corp.localhost:3000/employee/login"
puts "    - EMP001 / PIN: 1234 (John Smith)"
puts "    - EMP002 / PIN: 5678 (Jane Wilson)"
puts "    - EMP003 / PIN: 9999 (Mike Johnson)"
puts "  • tech-startup.localhost:3000/employee/login"
puts "    - DEV001 / PIN: 4321 (Bob Developer)"
puts "    - DEV002 / PIN: 2468 (Sarah Designer)"
puts "  • retail-chain.localhost:3000/employee/login"
puts "    - RET001 / PIN: 1111 (Lisa Cashier)"
puts "    - RET002 / PIN: 3333 (Tom Sales)"

puts "\n🚀 Ready to demo TimekeepPh!"
