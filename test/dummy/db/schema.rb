# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_210_101_000_001) do
  create_table 'users', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'email', null: false
    t.string 'type' # For STI support
    t.string 'special_field' # For InheritedModel
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['email'], name: 'index_users_on_email', unique: true
  end

  create_table 'posts', force: :cascade do |t|
    t.string 'title', null: false
    t.text 'content', null: false
    t.integer 'user_id', null: false
    t.integer 'comments_count', default: 0
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['user_id'], name: 'index_posts_on_user_id'
  end

  create_table 'comments', force: :cascade do |t|
    t.text 'content', null: false
    t.integer 'user_id', null: false
    t.integer 'post_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['user_id'], name: 'index_comments_on_user_id'
    t.index ['post_id'], name: 'index_comments_on_post_id'
  end

  create_table 'groups', force: :cascade do |t|
    t.string 'name', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
  end

  create_table 'memberships', force: :cascade do |t|
    t.integer 'user_id', null: false
    t.integer 'group_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index %w[user_id group_id], name: 'index_memberships_on_user_id_and_group_id', unique: true
  end

  create_table 'notifications', force: :cascade do |t|
    t.string 'message', null: false
    t.string 'notifiable_type', null: false
    t.integer 'notifiable_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index %w[notifiable_type notifiable_id], name: 'index_notifications_on_notifiable'
  end

  create_table 'tenant_models', force: :cascade do |t|
    t.string 'name', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
  end

  create_table 'tenant_posts', force: :cascade do |t|
    t.string 'title', null: false
    t.integer 'tenant_model_id', null: false
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.index ['tenant_model_id'], name: 'index_tenant_posts_on_tenant_model_id'
  end

  create_table 'active_storage_blobs', force: :cascade do |t|
    t.string 'key', null: false
    t.string 'filename', null: false
    t.string 'content_type'
    t.text 'metadata'
    t.string 'service_name', null: false
    t.bigint 'byte_size', null: false
    t.string 'checksum'
    t.datetime 'created_at', null: false
    t.index ['key'], name: 'index_active_storage_blobs_on_key', unique: true
  end

  create_table 'active_storage_attachments', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'record_type', null: false
    t.bigint 'record_id', null: false
    t.bigint 'blob_id', null: false
    t.datetime 'created_at', null: false
    t.index ['record_type', 'record_id', 'name', 'blob_id'], name: 'index_active_storage_attachments_uniqueness', unique: true
    t.index ['blob_id'], name: 'index_active_storage_attachments_on_blob_id'
  end

  add_foreign_key 'posts', 'users'
  add_foreign_key 'comments', 'users'
  add_foreign_key 'comments', 'posts'
  add_foreign_key 'memberships', 'users'
  add_foreign_key 'memberships', 'groups'
  add_foreign_key 'tenant_posts', 'tenant_models'
  add_foreign_key 'active_storage_attachments', 'active_storage_blobs', column: 'blob_id'
end
