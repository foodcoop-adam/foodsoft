require 'factory_girl'

FactoryGirl.define do

  factory :invite do
    user { create :user }
    email { Faker::Internet.email }
  end

end
