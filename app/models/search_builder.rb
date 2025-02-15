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

# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  class_attribute :avalon_solr_access_filters_logic
  self.avalon_solr_access_filters_logic = [:only_published_items, :limit_to_non_hidden_items]
  self.default_processor_chain += [:only_wanted_models]

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"MediaObject"'
  end

  def only_published_items(_permission_types = discovery_permissions, _ability = current_ability)
    [policy_clauses, 'workflow_published_sim:"Published"'].compact.join(" OR ")
  end

  def limit_to_non_hidden_items(_permission_types = discovery_permissions, _ability = current_ability)
    [policy_clauses,"(*:* NOT hidden_bsi:true)"].compact.join(" OR ")
  end

  # Overridden to skip for admin users
  def add_access_controls_to_solr_params(solr_parameters)
    if current_ability.cannot? :discover_everything, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << gated_discovery_filters.reject(&:blank?).join(' OR ')
      avalon_solr_access_filters_logic.each do |filter|
        solr_parameters[:fq] << send(filter, discovery_permissions, current_ability)
      end
      Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
    end
  end
end
