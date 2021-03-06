require 'spec_helper'

describe DailyEmailScheduler do
  describe "self.set_daily_email_jobs" do
    it "schedules an email job for a user" do
      user = create(:user)
      challenge = create(:challenge, :with_membership, :with_readings, begindate: "2050-01-01")
      #membership is automatically created when challenge is created.
      create(:membership, user: user, challenge: challenge)

      Timecop.travel("2050-01-01")

      DailyEmailScheduler.set_daily_email_jobs

      expect(DailyEmailWorker.jobs.size).to eq 2

      Timecop.return
    end

    it "schedules an email job for a user, but ignores job when membeship no longer exists" do
#      user = create(:user)
      challenge = create(:challenge, :with_membership, :with_readings, begindate: "2050-01-01")
#      membership = create(:membership, user: user, challenge: challenge)
      membership = challenge.memberships.first
      user = membership.user

      Timecop.travel("2050-01-01")

      DailyEmailScheduler.set_daily_email_jobs

      membership.destroy
      DailyEmailWorker.drain

      #first email is for created challenge, second is the dailyreading
      expect(ActionMailer::Base.deliveries.select { |email| email.To.to_s == user.email}).to eq []  #differentiates challenge email from 'daily email report' which also enqueues

      Timecop.return
    end

    it "schedules email's timing according to the user's preferences" do
      today = DateTime.now
      user1 = create(:user, time_zone: "Eastern Time (US & Canada)",
                     preferred_reading_hour: 7)
      user2 = create(:user, time_zone: "Pacific Time (US & Canada)",
                     preferred_reading_hour: 7)
      challenge = create(:challenge, :with_readings, begindate: today)
      create(:membership, user: user1, challenge: challenge)
      create(:membership, user: user2, challenge: challenge)

      #traveling to next day 0-hours
      Time.zone = "UTC"
      t = Time.local(today.year, today.month, today.day, 20, 0, 0)
      Timecop.travel(t)

      DailyEmailScheduler.set_daily_email_jobs

      a = Time.at(DailyEmailWorker.jobs.first["at"])
      b = Time.at(DailyEmailWorker.jobs.second["at"])
      time_lapse = ( b - a ) / 3600

      expect(time_lapse).to eq 3

      Timecop.return
    end

    it "schedules tomorrows reading according to the user's preferences" do
      today = DateTime.now
      user1 = create(:user, time_zone: "Eastern Time (US & Canada)",
                     preferred_reading_hour: 7)
      create(:challenge, :with_membership, :with_readings, begindate: today, owner: user1)

      #traveling to next day 0-hours
      Time.zone = "UTC"
      t = Time.local(today.year, today.month, today.day, 20, 0, 0)
      Timecop.travel(t)

      DailyEmailScheduler.set_daily_email_jobs

      reading_id_a = Time.at(DailyEmailWorker.jobs.first["args"][0].first) # first arg is now a collection of ids
      reading_date_a = Reading.find(reading_id_a).read_on.strftime("%D")

      tomorrow = DateTime.now+1
      expect(reading_date_a).to eq tomorrow.strftime("%D")

      Timecop.return
    end
  end


  describe "set_daily_email_jobs2" do  # another approach
    it "schedules an email job for two users with the same hour preference in different timezones" do
      challenge = create(:challenge, :with_membership, :with_readings, begindate: "2050-01-01")
      create(:membership, user: user_7am_eastern_time, challenge: challenge)
      create(:membership, user: user_7am_pacific_time, challenge: challenge)

      todays_date = Date.parse("2050-01-01")
      DailyEmailScheduler.set_daily_email_jobs2(todays_date)
      a = Time.at(DailyEmailWorker.jobs.second["at"])
      b = Time.at(DailyEmailWorker.jobs.last["at"])
      time_lapse = ( b - a ) / 3600
      expect(time_lapse.abs).to eq 3
    end
    it "schedules an email job for users in different timezones but at the same scheduled universal time" do
      challenge = create(:challenge, :with_readings, begindate: "2050-01-01")
      create(:membership, user: user_7am_eastern_time, challenge: challenge)
      create(:membership, user: user_4am_pacific_time, challenge: challenge)

      todays_date = Date.parse("2050-01-01")
      DailyEmailScheduler.set_daily_email_jobs2(todays_date)
      a = Time.at(DailyEmailWorker.jobs.second["at"])
      b = Time.at(DailyEmailWorker.jobs.last["at"])

      expect(a).to eq b
    end
  end

  def user_4am_pacific_time
    create(:user, time_zone: "Pacific Time (US & Canada)", preferred_reading_hour: 4)
  end

  def user_7am_pacific_time
    create(:user, time_zone: "Pacific Time (US & Canada)", preferred_reading_hour: 7)
  end

  def user_7am_eastern_time
    create(:user, time_zone: "Eastern Time (US & Canada)", preferred_reading_hour: 7)
  end

  def user_nkjv_version
    create(:user, time_zone: "Eastern Time (US & Canada)", bible_version: "NKJV", preferred_reading_hour: 7)
  end
end

