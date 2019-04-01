# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# seed the database with users who can access the admin page
[
  { email: 'rob@notch8.com', password: 'testing123'},
  { email: 'tbarnett@library.ucla.edu', password: 'uclaoh2019'},
  { email: 'genosanchez@library.ucla.edu', password: 'uclaoh2019'},
  { email: 'pghorpade@library.ucla.edu', password: 'uclaoh2019'}
].each do |set|
  next if User.where(email: set[:email]).first
  user = User.create!(email: set[:email], password: set[:password])
end

