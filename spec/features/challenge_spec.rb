require 'spec_helper'

describe 'Bible challenge creation', type: :feature do

  before do
    sign_up_and_in
  end

  context 'with valid data' do
    it 'creates a challenge' do
      create_challenge(name: "Some Challenge", subdomain: "somesubdomain", begindate: Time.now, enddate: Time.now + 1.day, chapterstoread: 'Matthew 1 - 5')
      page.should have_content 'Successfully created Challenge'
    end
  end

  context 'with invalid data' do
    
    it 'shows an explanation message on invalid dates' do
      create_challenge(name: "Some Challenge", subdomain: "somesubdomain", begindate: Time.now + 1.day, enddate: Time.now, chapterstoread: 'Matthew 1 - 5')
      page.should have_content 'The challenge begin and end dates must be sequential'
    end

    it 'shows an explanation message on invalid subdomain' do
      create_challenge(name: "Some Challenge", subdomain: "-", begindate: Time.now, enddate: Time.now + 1.day, chapterstoread: 'Matthew 1 - 5')
      page.should have_content 'Subdomain invalid format'
    end

    it 'shows an explanation message on invalid name' do
      create_challenge(name: ".", subdomain: "somesubdomain", begindate: Time.now, enddate: Time.now + 1.day, chapterstoread: 'Matthew 1 - 5')
      page.should have_content 'Name is too short (minimum is 3 characters)'
    end

  end

end