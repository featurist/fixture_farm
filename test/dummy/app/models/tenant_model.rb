# frozen_string_literal: true

class TenantModel < ApplicationRecord
  has_many :tenant_posts, dependent: :destroy

  validates :name, presence: true
end
