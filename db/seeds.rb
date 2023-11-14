# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# Set up a default admin user, if we are in a Development environment, otherwise, skip
if Rails.env.development? || Rails.env.test?
  u = User.find_or_create_by(email: ENV['ADMIN_EMAIL'] || 'admin@example.com')
  u.password = ENV['ADMIN_PASSWORD'] || 'password'
  u.save

  # Import the work with the video
  # OralHistoryItem.import_single("21198-zz002jxz7z")

  # Import additional works with audio
  # OralHistoryItem.import_single("21198-zz002bfs89")
end
