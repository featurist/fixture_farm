# frozen_string_literal: true

class TenantPost < ApplicationRecord
  belongs_to :tenant_model

  validates :title, presence: true
end
