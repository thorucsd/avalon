# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class WaveformJob < ActiveJob::Base
  queue_as :waveform

  PLAYER_WIDTH = Settings.waveform.player_width
  FINEST_ZOOM = Settings.waveform.finest_zoom
  SAMPLES_PER_FRAME = (Settings.waveform.sample_rate * FINEST_ZOOM) / PLAYER_WIDTH

  def perform(master_file_id, regenerate = false)
    master_file = MasterFile.find(master_file_id)
    return if master_file.waveform.content.present? && !regenerate || !master_file.has_audio?

    service = WaveformService.new(8, SAMPLES_PER_FRAME)
    uri = derivative_file_uri(master_file) || file_uri(master_file) || playlist_url(master_file)
    json = service.get_waveform_json(Addressable::URI.parse(uri))
    raise "No waveform generated for #{master_file.id}" if json.blank?

    master_file.waveform.content = Zlib::Deflate.deflate(json)
    master_file.waveform.mime_type = 'application/zlib'
    master_file.waveform.content_will_change!
    master_file.save
  ensure
    master_file.run_hook :after_processing if master_file.present?
  end

  private

    def file_uri(master_file)
      path = master_file.file_location
      locator = FileLocator.new(path)
      if path.present? && locator.exist?
        locator.uri
      else
        nil
      end
    end

    def derivative_file_uri(master_file)
      derivatives = master_file.derivatives

      # Find the lowest quality stream
      ['low', 'medium', 'high'].each do |quality|
        d = derivatives.select { |derivative| derivative.quality == quality }.first
        if d.present?
          loc = FileLocator.new(d.absolute_location)
          return loc.uri if loc.exist?
        end
      end

      nil
    end

    def playlist_url(master_file)
      streams = master_file.hls_streams
      hls_url = nil

      # Find the lowest quality stream
      ['high', 'medium', 'low'].each do |quality|
        quality_details = streams.find { |d| d[:quality] == quality }
        hls_url = quality_details[:url] if quality_details.present? && quality_details[:url]
      end

      hls_url.present? ? SecurityHandler.secure_url(hls_url, target: master_file.id) : nil
    end
end
