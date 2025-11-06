# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Default users
default_users = [
  {
    email: "admin@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Admin",
    last_name: "User"
  },
  {
    email: "john.doe@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "John",
    last_name: "Doe"
  },
  {
    email: "jane.smith@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Jane",
    last_name: "Smith"
  }
]

default_users.each do |user_attrs|
  user = User.find_or_initialize_by(email: user_attrs[:email])
  if user.new_record?
    user.assign_attributes(user_attrs)
    user.save!
    puts "Created user: #{user.email}"
  else
    puts "User already exists: #{user.email}"
  end
end
