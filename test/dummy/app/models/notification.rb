# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true

  validates :message, presence: true
end
