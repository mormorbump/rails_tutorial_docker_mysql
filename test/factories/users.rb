# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :user do
    name "MyString"
    email "MyString"
  end
end
