class TranscribeJob < ApplicationJob
  queue_as :transcribe

  attr_reader :tmp_dir, :video

  def perform(video)
    return if video.captions?

    @video = video
    @tmp_dir = Dir.mktmpdir

    download && extract_audio && transcribe && upload_captions &&
      video.update(captions: true)
  rescue StandardError => e
    binding.irb
  ensure
    FileUtils.remove_entry tmp_dir
  end

  def download
    system "wget -O #{input_path} #{video.download_url}"
  end

  def extract_audio
    system "ffmpeg -i #{input_path} -acodec pcm_s16le -ar 16000 -ac 1 #{audio_path}"
  end

  def transcribe
    system "whisper -m ~/Documents/projects/gorails/whisper.cpp/models/ggml-base.en.bin -of #{input_path} -ovtt #{audio_path}"
  end

  def upload_captions
    Bunny.new.upload_captions(guid: video.guid, captions_path: captions_path)
  end

  def input_path
    "#{tmp_dir}/#{video.guid}"
  end

  def audio_path
    input_path + ".wav"
  end

  def captions_path
    input_path + ".vtt"
  end
end
