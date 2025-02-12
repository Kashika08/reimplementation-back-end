# spec/support/roles_helper.rb
module RolesHelper
  def create_roles_hierarchy
    super_admin = Role.find_or_create_by(name: 'super_administrator') do |role|
      role.parent = nil # Adjust parent settings accordingly
    end
    admin = Role.find_or_create_by(name: 'administrator') do |role|
      role.parent = super_admin
    end
    instructor = Role.find_or_create_by(name: 'instructor') do |role|
      role.parent = admin
    end
    ta = Role.find_or_create_by(name: 'ta') do |role|
      role.parent = instructor
    end
    student = Role.find_or_create_by(name: 'student') do |role|
      role.parent = ta
    end

    { super_admin:, admin:, instructor:, ta:, student: }
  end

end