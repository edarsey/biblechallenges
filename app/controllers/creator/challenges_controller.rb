class Creator::ChallengesController < ApplicationController

  before_filter :authenticate_user!, except: [:show]
  before_filter :find_challenge, only: [:show, :destroy]

  def new
    @challenge = Challenge.new
  end

  def index
    @challenges = current_user.created_challenges
  end

  def show
    @readings  = @challenge.readings.order(:date)
  end

  def find_challenge
    @challenge = Challenge.find_by_id(params[:id])
    redirect_to challenges_url if @challenge.nil?
  end

  def create
    @challenge = current_user.created_challenges.build(challenge_params)

    # this seems terrible; is there a better way?  #jim
    if @challenge.save
      flash[:notice] = "Successfully created Challenge" 
      #@challenge.members << current_user @Phil - we wrote a call back in user model. Which should we keep?
      readings = ReadingsGenerator.new(@challenge.begindate, 
                                      @challenge.chapters_to_read,
                                      days_of_week_to_skip: days_of_week_to_skip,
                                      dates_to_skip: challenge_params[:dates_to_skip],
                                      ).generate
      readings.each do |r|
        r.challenge_id = @challenge.id
        r.save
      end
      ChallengeCompletion.new(@challenge)
    end

    redirect_to [:member, @challenge]
  end

  def destroy
    @challenge.destroy
    redirect_to creator_challenges_path
  end

  private

  def days_of_week_to_skip
    if params[:days_to_skip]
      params[:days_to_skip].map{|i| i.to_i} 
    end
  end

  def challenge_params
    params.require(:challenge).permit(:owner_id, :name, :dates_to_skip, :begindate, :enddate, :chapters_to_read)
  end
end
