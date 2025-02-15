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

FactoryBot.define do
  factory :supplemental_file do
    label { Faker::Lorem.word }

    trait :with_attached_file do
      file { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'collection_poster.png'), 'image/png') }
    end

    trait :with_transcript_file do
      file { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.vtt'), 'text/vtt')}
    end

    trait :with_transcript_tag do
      tags { ['transcript'] }
    end
  end
end 
