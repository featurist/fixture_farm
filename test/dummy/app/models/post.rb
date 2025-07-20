# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true

  after_create :notify_followers

  private

  def notify_followers
    notifications.create!(message: "New post: #{title}")
  end
end
