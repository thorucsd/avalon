User.instance_eval do
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    logger.debug "#{access_token.inspect}"

    email = access_token.info.email
    # Ares DB needs to query using user ID.
    # TODO: confirm that downcase'd usernames match in Ares
    username = email.split('@').first.downcase

    user = User.find_or_create_by_username_or_email(username, email)
#    in_ldap_group = user.ldap_groups.any? { |g| Avalon::GROUP_LDAP_FILTER.include?(g) }

    raise "Finding user (#{ user }) failed: #{ user.errors.full_messages }" unless user.persisted?
#    raise Avalon::NotAuthorized unless in_ldap_group || Ability.new(user).is_administrator?

    user
  end
  
#  def self.ldap_member_of(cn)
#    return [] unless defined? Avalon::GROUP_LDAP
#    cn = cn.split('@').first.downcase
#    entry = Avalon::GROUP_LDAP.search(:base => Avalon::GROUP_LDAP_TREE, filter: Net::LDAP::Filter.eq('cn', cn), :attributes => ["memberof"]).first
#    entry.nil? ? [] : entry["memberof"].collect {|mo| mo.split(',').first.split('=')[1]}
#  end
end
