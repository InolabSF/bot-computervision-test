class Image < ApplicationRecord
  validates_presence_of :url
   mount_uploader :url, ImageUploader
   belongs_to :user
end
