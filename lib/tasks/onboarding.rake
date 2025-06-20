namespace :onboarding do
  desc "Create a new customer account with admin user"
  task :create_account, [ :company_name, :subdomain, :admin_name, :admin_email ] => :environment do |t, args|
    company_name = args[:company_name]
    subdomain = args[:subdomain]
    admin_name = args[:admin_name]
    admin_email = args[:admin_email]

    # Validate required arguments
    if company_name.blank? || subdomain.blank? || admin_name.blank? || admin_email.blank?
      puts "❌ Usage: bin/rails onboarding:create_account['Company Name','subdomain','Admin Name','admin@email.com']"
      puts "   Example: bin/rails onboarding:create_account['Acme Corp','acme-corp','John Smith','john@acme-corp.com']"
      exit 1
    end

    # Normalize subdomain
    subdomain = subdomain.strip.downcase

    # Validate subdomain format
    unless subdomain.match?(/\A[a-z0-9\-]+\z/)
      puts "❌ Invalid subdomain format. Use only lowercase letters, numbers, and hyphens."
      exit 1
    end

    # Check if subdomain already exists
    if Account.exists?(subdomain: subdomain)
      puts "❌ Subdomain '#{subdomain}' already exists. Please choose a different subdomain."
      exit 1
    end

    # Check if admin email already exists
    if User.exists?(email: admin_email.strip.downcase)
      puts "❌ Admin email '#{admin_email}' already exists. Please use a different email."
      exit 1
    end

    puts "🚀 Creating new customer account..."
    puts "   Company: #{company_name}"
    puts "   Subdomain: #{subdomain}.timekeep.ph"
    puts "   Admin: #{admin_name} (#{admin_email})"
    puts ""

    begin
      ActiveRecord::Base.transaction do
        # Create account
        account = Account.create!(
          name: company_name,
          subdomain: subdomain,
          active: true
        )
        puts "✅ Account created: #{account.name}"

        # Generate secure password
        password = SecureRandom.hex(8)

        # Create admin user
        admin_user = User.create!(
          account: account,
          name: admin_name,
          email: admin_email,
          password: password,
          password_confirmation: password,
          role: :admin
        )
        puts "✅ Admin user created: #{admin_user.name}"

        # Create default branch
        default_branch = Branch.create!(
          account: account,
          name: "Main Office",
          address: "Please update this address",
          active: true
        )
        puts "✅ Default branch created: #{default_branch.name}"

        puts ""
        puts "🎉 Account creation completed successfully!"
        puts ""
        puts "📋 Customer Information:"
        puts "   Company: #{account.name}"
        puts "   Login URL: https://#{subdomain}.timekeep.ph"
        puts "   Admin Email: #{admin_user.email}"
        puts "   Temporary Password: #{password}"
        puts ""
        puts "📧 Next Steps:"
        puts "   1. Send login credentials to customer via secure channel"
        puts "   2. Customer should log in and change password"
        puts "   3. Customer should update branch address and add employees"
        puts "   4. Test employee clock-in functionality"
        puts ""
        puts "🔗 Employee Login URL: https://#{subdomain}.timekeep.ph/employee/login"
      end
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Error creating account: #{e.message}"
      exit 1
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "List all customer accounts"
  task :list_accounts => :environment do
    accounts = Account.includes(:users, :branches, :employees).order(:created_at)

    if accounts.empty?
      puts "📭 No customer accounts found."
      return
    end

    puts "📊 Customer Accounts Summary"
    puts "=" * 50
    puts ""

    accounts.each do |account|
      status = account.active? ? "🟢 Active" : "🔴 Inactive"
      users_count = account.users.count
      branches_count = account.branches.count
      employees_count = account.employees.count

      puts "#{status} #{account.name}"
      puts "   Subdomain: #{account.subdomain}.timekeep.ph"
      puts "   Users: #{users_count} | Branches: #{branches_count} | Employees: #{employees_count}"
      puts "   Created: #{account.created_at.strftime('%Y-%m-%d')}"
      puts ""
    end

    puts "📈 Total: #{accounts.count} accounts"
  end

  desc "Show detailed account information"
  task :show_account, [ :subdomain ] => :environment do |t, args|
    subdomain = args[:subdomain]

    if subdomain.blank?
      puts "❌ Usage: bin/rails onboarding:show_account[subdomain]"
      puts "   Example: bin/rails onboarding:show_account[acme-corp]"
      exit 1
    end

    account = Account.find_by(subdomain: subdomain.strip.downcase)

    unless account
      puts "❌ Account with subdomain '#{subdomain}' not found."
      exit 1
    end

    puts "🏢 Account Details: #{account.name}"
    puts "=" * 50
    puts "Subdomain: #{account.subdomain}.timekeep.ph"
    puts "Status: #{account.active? ? '🟢 Active' : '🔴 Inactive'}"
    puts "Created: #{account.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    puts ""

    # Users
    puts "👥 Users (#{account.users.count}):"
    account.users.each do |user|
      puts "   • #{user.name} (#{user.email}) - #{user.role.capitalize}"
    end
    puts ""

    # Branches
    puts "🏪 Branches (#{account.branches.count}):"
    account.branches.each do |branch|
      status = branch.active? ? "🟢" : "🔴"
      employee_count = branch.employees.count
      puts "   #{status} #{branch.name} - #{employee_count} employees"
      puts "     Address: #{branch.address}"
    end
    puts ""

    # Employees
    puts "👷 Employees (#{account.employees.count}):"
    account.employees.includes(:branch).each do |employee|
      status = employee.active? ? "🟢" : "🔴"
      puts "   #{status} #{employee.name} (#{employee.employee_id}) - #{employee.branch.name}"
    end
    puts ""

    # Recent activity
    recent_entries = account.clock_entries.includes(:employee, :branch)
                           .order(created_at: :desc).limit(5)

    if recent_entries.any?
      puts "⏰ Recent Clock Entries:"
      recent_entries.each do |entry|
        time = entry.created_at.strftime('%m/%d %H:%M')
        puts "   #{time} - #{entry.employee.name} #{entry.entry_type.tr('_', ' ')} at #{entry.branch.name}"
      end
    else
      puts "⏰ No clock entries yet"
    end
  end

  desc "Deactivate a customer account"
  task :deactivate_account, [ :subdomain ] => :environment do |t, args|
    subdomain = args[:subdomain]

    if subdomain.blank?
      puts "❌ Usage: bin/rails onboarding:deactivate_account[subdomain]"
      exit 1
    end

    account = Account.find_by(subdomain: subdomain.strip.downcase)

    unless account
      puts "❌ Account with subdomain '#{subdomain}' not found."
      exit 1
    end

    if !account.active?
      puts "⚠️  Account '#{account.name}' is already inactive."
      return
    end

    print "❓ Are you sure you want to deactivate '#{account.name}'? (y/N): "
    confirmation = STDIN.gets.chomp.downcase

    if confirmation == 'y' || confirmation == 'yes'
      account.update!(active: false)
      puts "✅ Account '#{account.name}' has been deactivated."
      puts "   Subdomain #{subdomain}.timekeep.ph will return 404"
    else
      puts "❌ Deactivation cancelled."
    end
  end

  desc "Reactivate a customer account"
  task :reactivate_account, [ :subdomain ] => :environment do |t, args|
    subdomain = args[:subdomain]

    if subdomain.blank?
      puts "❌ Usage: bin/rails onboarding:reactivate_account[subdomain]"
      exit 1
    end

    account = Account.find_by(subdomain: subdomain.strip.downcase)

    unless account
      puts "❌ Account with subdomain '#{subdomain}' not found."
      exit 1
    end

    if account.active?
      puts "✅ Account '#{account.name}' is already active."
      return
    end

    account.update!(active: true)
    puts "✅ Account '#{account.name}' has been reactivated."
    puts "   Subdomain #{subdomain}.timekeep.ph is now accessible"
  end
end