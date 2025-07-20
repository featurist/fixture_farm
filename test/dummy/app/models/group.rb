# frozen_string_literal: true

class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, presence: true
end
