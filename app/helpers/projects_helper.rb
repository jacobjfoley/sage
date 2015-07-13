module ProjectsHelper

  # Determines if a user would be leaving a project, as opposed to deleting.
  def leaving?(user, project)

    # Find how many administrators are in this project.
    admins = UserRole.where(project_id: project.id, position:"Administrator").count

    # Find whether this user is an administrator.
    role = UserRole.where(user_id: user.id, project_id: project.id).first

    # If the user is the last administrator:
    if (admins == 1) && (role.position.eql? "Administrator")

      # User leaving will cause project deletion.
      return false
    else

      # User is free to leave.
      return true
    end
  end
end
