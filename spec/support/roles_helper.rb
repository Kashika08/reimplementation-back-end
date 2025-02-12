# spec/support/roles_helper.rb
module RolesHelper
  def create_roles_hierarchy
    # Create roles in hierarchy using the factory
    super_admin = Role.find_or_create_by(:role, :super_administrator)
    admin = Role.find_or_create_by(:role, :administrator, :with_parent, parent: super_admin)
    instructor = Role.find_or_create_by(:role, :instructor, :with_parent, parent: admin)
    ta = Role.find_or_create_by(:role, :ta, :with_parent, parent: instructor)
    student = Role.find_or_create_by(:role, :student, :with_parent, parent: ta)

    # Return the roles as a hash for easy access in specs
    {
      super_admin: super_admin,
      admin: admin,
      instructor: instructor,
      ta: ta,
      student: student
    }
  end
end