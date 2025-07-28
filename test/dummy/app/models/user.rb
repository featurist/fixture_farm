# frozen_string_literal: true

class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :notifications, as: :notifiable, dependent: :destroy

  has_one_attached :avatar

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  after_create :send_welcome_notification

  private

  def send_welcome_notification
    notifications.create!(message: "Welcome #{name}!")
  end
end
