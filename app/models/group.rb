class Group < ActiveRecord::Base

  belongs_to :user
  belongs_to :challenge
  has_many :memberships

  validates :user, :challenge, presence: true

end