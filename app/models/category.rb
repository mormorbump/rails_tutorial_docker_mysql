class User < ApplicationRecord
    before_validation -> {puts "before_validationが呼ばれました"}
    after_validation -> {puts "after_validationが呼ばれました"}
    before_save -> {puts "before_saveが呼ばれました"}
    before_update -> {puts "before_updateが呼ばれました"}
    before_create -> {puts "before_createが呼ばれました"}
    after_create -> {puts "after_createが呼ばれました"}
    after_update -> {puts "after_updateが呼ばれました"}
    after_save -> {puts "after_saveが呼ばれました"}
    after_commit -> {puts "after_commitが呼ばれました"}
end

user = User.new
p 'new完了'
user.save