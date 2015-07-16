require 'spec_helper'

describe Membership do

  describe "Validations" do

    it "has a valid factory" do
      expect(create(:membership)).to be_valid
    end

    it { should validate_presence_of(:challenge_id) }
    it { should validate_presence_of(:bible_version) }
    it { should validate_inclusion_of(:bible_version).in_array(Membership::BIBLE_VERSIONS)}
    it do # This has to be written different. Check https://github.com/thoughtbot/shoulda-matchers#validate_uniqueness_of
      create(:membership)
      should validate_uniqueness_of(:user_id).scoped_to(:challenge_id)
    end

    it "is invalid without a challenge_id" do
      membership = build(:membership, challenge_id: nil)
      expect(membership).to have(1).errors_on(:challenge_id)
    end

    context 'when a user has already joined a challenge' do
      let(:user){create(:user)}
      let(:challenge){create(:challenge)}
      let!(:membership){create(:membership, challenge: challenge, user: user)}

      it 'does not allow to re-join again' do
        expect(build(:membership, challenge: challenge, user: user)).to_not be_valid
      end
    end
  end

  describe "Relations" do
    it { should belong_to(:user) }
    it { should belong_to(:challenge) }
    it { should belong_to(:group) }
    it { should have_many(:readings).through(:challenge) }
    it { should have_many(:membership_readings) }
  end

  describe "Class methods" do
    describe '#send_daily_emails' do
      it "sends email according to user's timezone and time preference", skip: true do
        pending
        challenge = create(:challenge, :with_readings, begindate: Date.today)
        membership = create(:membership, challenge: challenge)
        user = membership.user
        create(:profile, time_zone: 'Eastern Time (US & Canada)', preferred_reading_hour: DateTime.now.strftime("%H"), user: user)
        Membership.send_daily_emails
        successful_sending_email = ActionMailer::Base.deliveries.last
        expect(successful_sending_email.to).to match_array [user.email] 
      end

      it "sends email according to user's timezone and time preference", skip: true do
        pending
        challenge = create(:challenge, :with_readings, begindate: Date.today)
        membership = create(:membership, challenge: challenge)
        user = membership.user
        create(:profile, time_zone: 'Hawaii', preferred_reading_hour: 6)
        Membership.send_daily_emails
        successful_sending_email = ActionMailer::Base.deliveries.last
        expect(successful_sending_email.to).to match_array [user.email] 
      end
    end
  end

  describe 'Instance methods' do
    describe "#associate_statistics" do
      it "creates named statistics and associates them with new membership" do
        challenge = create(:challenge)
        membership = create(:membership, challenge: challenge)

        membership.associate_statistics

        # somehow verify that all the statistics are present
        MembershipStatistic.descendants.each do |mem_stat|
          #mem_stat.name will hold the type of each possible membership statistic
          result = membership.membership_statistics.find_by_type(mem_stat.name)
          expect(result).to_not be_nil
        end
      end
    end

    describe '#completed?' do
      it "returns true if all the chapters have been read" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1 -2')
        membership = create(:membership, challenge: challenge)
        membership.readings[0..1].each do |r| # read first two
          create(:membership_reading, reading: r, membership: membership)
        end
        expect(membership.completed?).to eq true
      end
      it "returns false if not all the chapters have been read" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1-3')
        challenge.generate_readings
        membership = create(:membership, challenge: challenge)
        membership.readings[0..1].each do |r| # read first two
          create(:membership_reading, reading: r, membership: membership)
        end
        expect(membership.completed?).to eq false
      end
    end
  end

  describe 'Callbacks' do
    describe 'After create' do
      describe '#associate_readings' do
    #    let(:membership){create(:membership)}
    let(:newchallenge){create(:challenge_with_readings, :with_membership)}
    let(:membership){newchallenge.memberships.first}
        it 'associates all the readings from its challenge' do
          expect(membership.readings).to match_array(membership.challenge.readings)
        end
        it 'sends out a thanks for joining email' do
            membership.save
            membership.run_callbacks(:commit)
            NewMembershipEmailWorker.drain
            expect(ActionMailer::Base.deliveries.last.subject).to include "Thanks for joining"
        end
        it 'sends out a verses email if challenge started that day' do
            membership.save
            membership.run_callbacks(:commit)
            DailyEmailWorker.drain
            expect(ActionMailer::Base.deliveries.first.subject).to include "Bible Challenge reading for"
        end
      end

      describe '#send_todays_reading' do
        it "sends todays reading after creation if it exists", skip: true do
          pending
          user = create(:user)
          challenge = create(:challenge, begindate: Date.today)  
          membership = build(:membership, challenge: challenge, user: user)
          #MembershipReadingMailer.should_receive(:daily_reading_email).and_return(double("MembershipReadingMailer", deliver: true))  #params?
          expect(ReadingMailer).to receive(:daily_reading_email).and_return(double("MembershipReadingMailer", deliver: true))  #params?
          membership.save
        end
        it "does not send todays reading after creation if it does not exist" do
          user = create(:user)
          challenge = create(:challenge, begindate: Date.tomorrow) 
          membership = build(:membership, challenge: challenge, user: user)
          expect(ReadingMailer).not_to receive(:daily_reading_email)
          membership.save
        end
      end
    end
  end
end
