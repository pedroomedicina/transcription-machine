class Video < ApplicationRecord
  scope :uncaptioned, -> { where(captions: false) }
  scope :captioned, -> { where(captions: true) }

  after_commit :transcribe, on: [ :create, :update ], unless: :captions?

  def download_url
    "https://#{Rails.application.credentials.bunny_zone}.b-cdn.net/#{guid}/play_36p.mp4"
  end

  def transcribe
    TranscribeJob.perform_later(self)
  end
end
