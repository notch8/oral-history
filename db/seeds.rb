# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# Set up a default admin user, if we are in a Development environment, otherwise, skip
if Rails.env.development? || Rails.env.test? || Rails.env.production?
  u = User.find_or_create_by(email: ENV['ADMIN_EMAIL'] || 'admin@example.com')
  u.password = ENV['ADMIN_PASSWORD'] || 'testing123'
  u.password_confirmation = ENV['ADMIN_PASSWORD']
  u.save
OralHistoryItem.import_single('21198-zz0009049n')
OralHistoryItem.import_single('21198-zz002kf3rs')
OralHistoryItem.import_single('21198-zz002knbn9')
OralHistoryItem.import_single('21198-zz000900nw')
OralHistoryItem.import_single('21198-zz002dx5z2')
OralHistoryItem.import_single('21198-zz002ddfz6')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
# OralHistoryItem.import_single('')
end
