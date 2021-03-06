require 'spec_helper'

feature 'User invites friends via email' do
  let(:user) {create(:user)}
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  before(:each) do
    login(user)
  end

  scenario 'User adds a non-email format' do
    challenge = create(:challenge, :with_readings, owner_id: user.id)
    create(:membership, challenge: challenge, user: user)
    visit member_challenge_path(challenge)
    click_button 'Add friends'
    fill_in "addFriendsInput", with: 'a;oij;oi23o'
    click_button "Add"
    expect(page).to have_content("Please enter a valid email")
  end

  scenario 'User adds an invalid user due to invalid email' do
    challenge = create(:challenge, :with_readings, owner_id: user.id)
    create(:membership, challenge: challenge, user: user)
    visit member_challenge_path(challenge)
    click_button 'Add friends'
    fill_in "addFriendsInput", with: '__^^@gmail'
    click_button "Add"
    expect(page).to have_content("Please enter a valid email")
  end

  scenario 'sends a successfully email to new user to Bible Challenge' do
    Sidekiq::Testing.inline! do
      challenge = create(:challenge, :with_readings, owner_id: user.id)
      create(:membership, challenge: challenge, user: user)
      visit member_challenge_path(challenge)
      fill_in 'invite_email', with: 'fakedude@example.com'
      click_button "Add"
      successful_creation_email = ActionMailer::Base.deliveries.last
      expect(successful_creation_email.to).to match_array ["fakedude@example.com"]
    end
  end

  scenario 'User adds a friend who is not signed up with Bible Challenge' do
    Sidekiq::Testing.inline! do
      challenge = create(:challenge, :with_readings, owner_id: user.id)
      create(:membership, challenge: challenge, user: user)
      visit member_challenge_path(challenge)
      expect{
        fill_in 'invite_email', with: 'fakedude@example.com'
        click_button "Add"
      }.to change(User, :count).by(1)
      expect(challenge.memberships.count).to eq 2
      successful_creation_email = ActionMailer::Base.deliveries.first
      expect(successful_creation_email.to).to match_array ["fakedude@example.com"]
      expect(successful_creation_email.body).to have_content "Password"
    end
  end

  scenario 'User adds a friend who is already signed up with Bible Challenge' do
    Sidekiq::Testing.inline! do
      challenge = create(:challenge, :with_readings, owner_id: user.id)
      create(:membership, challenge: challenge, user: user)
      user2 = create(:user)
      visit member_challenge_path(challenge)
      expect{
        fill_in 'invite_email', with: user2.email
        click_button "Add"
      }.to change(User, :count).by(0)
      expect(challenge.memberships.count).to eq 2
      successful_creation_email = ActionMailer::Base.deliveries.first
      expect(successful_creation_email.to).to match_array [user2.email]
      expect(successful_creation_email.subject).to have_content "Thanks for joining"
    end
  end

  scenario 'User adds a friend who is already in the challenge' do
    challenge = create(:challenge, :with_readings, owner_id: user.id)
    create(:membership, challenge: challenge, user: user)
    user2 = create(:user)
    create(:membership, challenge: challenge, user: user2)
    visit member_challenge_path(challenge)
    expect{
      fill_in 'invite_email', with: user2.email
      click_button "Add"
    }.to change(Membership, :count).by(0)
    expect(page).to have_content("already in this challenge")
  end
end


