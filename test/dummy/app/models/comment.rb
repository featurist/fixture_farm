class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  validates :content, presence: true
  
  after_create :update_post_comments_count
  
  private
  
  def update_post_comments_count
    post.update_column(:comments_count, post.comments.count)
  end
end