require "spec_helper"

feature "User management" do
  scenario "adds a new user" do
    admin = create(:admin)
    sign_in admin

    visit root_path
    expect{
      click_link "Users"
      click_link "New User"
      fill_in "Email", with: "newuser@example.com"
      find("#password").fill_in "Password", with: "password51"
      find("#password_confirmation").fill_in "Password confirmation",
        with: "password51"
      click_button "Create User"
  }.to change(User, :count).by(1)
  end
end
