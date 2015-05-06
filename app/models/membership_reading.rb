# == Schema Information
#
# Table name: membership_readings
#
#  id            :integer          not null, primary key
#  membership_id :integer
#  reading_id    :integer
#  state         :string(255)      default("unread")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class MembershipReading < ActiveRecord::Base

  include UrlHashable


  # Scopes
  default_scope {includes(:reading).order('readings.date')}
  scope :read, -> {where(state: 'read')}
  scope :unread, -> {where(state: 'unread')}

  # Constants
  STATES = %w(read unread)

  # Relations
  belongs_to :membership
  belongs_to :reading

  #delegations
  delegate :date, to: :reading

  # Validations
  validates :membership_id, presence: true
  validates :reading_id, presence: true
  validates :state, inclusion: {in: STATES}

  def read?
    state == 'read'
  end

  def self.send_daily_emails
    MembershipReading.unread.joins(:reading).where("readings.date = ?",Date.today).each do |mr|
      puts "Sending email to: #{mr.membership.user.email} from #{mr.membership.challenge.name} challenge."
      MembershipReadingMailer.daily_reading_email(mr).deliver_now
    end
  end
end
