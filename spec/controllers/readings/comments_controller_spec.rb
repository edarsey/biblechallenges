require 'spec_helper'

describe Readings::CommentsController, "Actions" do
  let(:challenge) {create(:challenge)}
  describe "Guest Posting" do
    describe "POST #create" do
      it "redirects to login page" do
        post :create, reading_id: 1, comment: attributes_for(:reading_comment)
        expect(response).to redirect_to new_user_session_path
      end
    end
  end


  describe "Delete #delete" do

    before do
      request.env["HTTP_REFERER"] = "where_i_came_from"  #to test redirect back
    end

    it "should destroy the current comment if the current_user owns it" do
      current_user= create(:user)
      sign_in :user, current_user
      challenge = create(:challenge)
      membership = create(:membership, user: current_user, challenge: challenge)
      reading = membership.readings.first
      comment = create(:reading_comment, user: current_user, commentable: reading) #comment on a reading
      expect{ delete :destroy, reading_id: reading.id, id: comment.id}.to change(Comment, :count).by(-1)
    end

    it "should not destroy the comment if the current_user does not own it" do
      current_user= create(:user)
      challenge = create(:challenge)
      membership = create(:membership, user: current_user, challenge: challenge)
      reading = membership.readings.first
      comment = create(:reading_comment, user: current_user, commentable: reading) #comment on a reading
      randomuser = create(:user)
      sign_in :user, randomuser
      expect{ delete :destroy, reading_id: reading.id, id: comment.id}.not_to change(Comment, :count)
    end

    it "should redirect to login if the user is not logged in" do
      current_user= create(:user)
      challenge = create(:challenge)
      membership = create(:membership, user: current_user, challenge: challenge)
      reading = membership.readings.first
      comment = create(:reading_comment, user: current_user, commentable: reading) #comment on a reading
      delete :destroy, reading_id: reading.id, id: comment.id
      expect(response).to redirect_to new_user_session_url
    end


  end



  describe "POST #create" do
    let!(:current_user) {create(:user)}
    let!(:membership) {create(:membership, user: current_user, challenge: challenge)}
    let(:reading) { membership.readings.first}
    let(:newcomment_attr) {attributes_for(:reading_comment, user: current_user, commentable: membership.readings.first)}
    let!(:existing_comment) {create(:reading_comment, user: current_user, commentable: membership.readings.first)}


    before do
      sign_in :user, current_user
      request.env["HTTP_REFERER"] = "where_i_came_from"  #to test redirect back
    end

    it "redirects to the user's profile if the user does not have a login name" do
      current_user.username = nil
      current_user.save
      post :create, reading_id: reading.id, comment: newcomment_attr
      expect(response).to redirect_to edit_user_registration_url
    end

    it "creates a new reading comment" do
      expect{post :create, reading_id: reading.id, comment: newcomment_attr
      }.to change(Comment, :count).by(1)

    end
    it "should redirect to :back if not params[:location] is not  provided" do
      post :create, reading_id: reading.id, comment: newcomment_attr
      expect(response).to redirect_to "where_i_came_from"
    end

    it "should redirect to params[:location] if it's provided" do
      post :create, reading_id: reading.id, comment: newcomment_attr, location: new_user_session_path
      should redirect_to(new_user_session_path)
    end

    it "should redirect to params[:location] if the comment is invalid" do
      post :create, reading_id: reading.id, comment: build(:reading_comment, content: nil), location: new_user_session_path
      should redirect_to(new_user_session_path)
    end

    it "should set the flash" do
      post :create, reading_id: reading.id, comment: newcomment_attr
      should set_the_flash
    end

    it "does not allow a user to create a comment for a reading he is not part of (through a challenge)" do
      randomuser = FactoryGirl.create(:user)
      sign_out current_user
      sign_in :user, randomuser
      expect{
        post :create, reading_id: reading.id, comment: attributes_for(:reading_comment, commentable_type: "Reading", commentable_id: reading.id), location: reading_path(reading.id)
      }.to_not change(Comment, :count).by(1)
    end



  end
end