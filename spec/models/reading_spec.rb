require 'spec_helper'

describe Reading do

  describe "Validations" do

    it "has a valid factory" do
      expect(create(:reading)).to be_valid
    end

    it { should validate_presence_of(:chapter_id) }
    it { should validate_presence_of(:challenge_id) }
    it { should validate_presence_of(:read_on) }
  end 
  describe "Delegations" do
    it { should delegate_method(:owner).to(:challenge) }
  end

  describe "Relations" do
    it { should belong_to(:challenge) }
    it { should belong_to(:chapter) }
    it { should have_many(:memberships).through(:membership_readings) }
    it { should have_many(:membership_readings) }
  end

  describe "Scopes" do

    describe "on_date" do
      it "should return all readings scheduled for the given date" do
        create_list(:reading, 2, read_on: "2050-01-01")
        create_list(:reading, 1, read_on: "2050-01-02")

        expect(Reading.on_date("2050-01-01").size).to eq 2
        
      end
    end
    describe "to_date" do
      let!(:challenge){create(:challenge, chapters_to_read: 'Mar 1 -7')}
      let(:membership){create(:membership, challenge: challenge)}

      it "should find all readings up to and including the passed date" do
        challenge.generate_readings
        expect(membership.readings.to_date(challenge.begindate + 1.day)).to have(2).items
      end
    end
  end

  describe "Instance Methods" do
    describe "read_by?" do
      it "returns false if the reading has been read by the passed in user" do
        user = create(:user)
        challenge = create(:challenge_with_readings, chapters_to_read: 'Mar 1 -2')
        create(:membership, user: user, challenge: challenge)
        reading = challenge.readings.first
        expect(reading.read_by?(user)).to eq false
      end
      it "returns true if the reading has been read by the passed in user" do
        user = create(:user)
        challenge = create(:challenge_with_readings, chapters_to_read: 'Mar 1 -2')
        membership = create(:membership, user: user, challenge: challenge)
        reading = challenge.readings.first
        create(:membership_reading, membership: membership, reading: reading, user_id: user.id)
        expect(reading.read_by?(user)).to eq true
      end
    end
    describe "last_readers" do
      it "should return a collection of the last x readers" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1 -2')
        challenge.generate_readings
        reading = challenge.readings.first
        m1 = create(:membership, challenge: challenge)
        m2 = create(:membership, challenge: challenge)
        create(:membership_reading, reading: reading, membership: m1)
        create(:membership_reading, reading: reading, membership: m2)
        expect(reading.last_readers(2)).to match_array [m1.user, m2.user]
        
      end

      it "should return an empty collection of noone has read" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1 -2')
        challenge.generate_readings
        reading = challenge.readings.first
        create(:membership, challenge: challenge)
        create(:membership, challenge: challenge)
        expect(reading.last_readers(2)).to match_array []
      end
    end
    describe "next_reading" do
      it "should return the next sequential reading for a challenge reading instance" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1-2')
        challenge.generate_readings
        reading = challenge.readings.first
        reading2 = challenge.readings.last
        expect(reading.next_reading).to eq reading2
      end
    end
    describe "last_challenge_reading?" do
      it "should return true if reading instance is the last of challenge readings" do
        challenge = create(:challenge, chapters_to_read: 'Mar 1-2')
        challenge.generate_readings
        reading2 = challenge.readings.last
        reading = challenge.readings.first
        expect(reading2.last_challenge_reading?).to eq true
        expect(reading.last_challenge_reading?).to be_falsey
      end
    end
  end
end
