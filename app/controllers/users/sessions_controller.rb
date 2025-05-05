class Users::SessionsController < Devise::SessionsController
  def create
    super do |resource|
      if resource.persisted?
        # Redirect to stored location or admin page
        redirect_to stored_location_for(:user) || admin_path and return
      end
    end
  end

  def destroy
    super do |resource|
      # Redirect to root page after logout
      redirect_to root_path and return
    end
  end
end 