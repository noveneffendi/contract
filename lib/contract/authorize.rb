# This module to override cancan authorize method if object contain with query string parameter
module Authorization
	def authorize_url(url)
		if url.present?
			user_group = UserGroup.find(current_user.try(:user_group_id))
			menu_id = UserMenu.where(:url => url).first.try(:id)
			user_access = UserGroupUserMenu.where(:user_menu_id => menu_id.to_i, :user_group_id => user_group.id.to_i).last
			if user_access.nil?
				@authorize = false
			else
				@authorize = true
			end
		end
	end

	# Check additional resource control for current_user
	def load_additional_resource(url,type=0)
		# type = 0 => print, 1 => revise
		if url.present?
			authorize = authorize_url(url)
			if authorize == true
				user_group = UserGroup.find(current_user.try(:user_group_id))
				menu_id = UserMenu.where(:url => url).first.try(:id)
				user_access = UserGroupUserMenu.where(:user_menu_id => menu_id.to_i, :user_group_id => user_group.id.to_i).last
				if user_access.present?
					if type.to_i == 0 # Print
						allow = user_access.can_print
					elsif type.to_i == 1 # Revise
						allow = user_access.can_revise
					else	
						allow = false
					end
				else
					allow = false
				end
			else
				# raise CanCan::AccessDenied
				allow = false
			end
		else
			# raise CanCan::AccessDenied
			allow = false
		end
		return allow
	end

	# Use this authorise method to change authorize_resource cancan if object has query string parameter
	def authorize_access(url,param_value=nil)
	    user = User.find(current_user.id)

	    # if @split_tax_and_non_tax_transaction == 1
	    if param_value.present?
	        if param_value.to_s == 'x' || param_value.to_s == 'l' || param_value.to_s == 'm'
		        status = authorize_url("/#{url}?tt=#{param_value.to_s}")
		    elsif param_value.is_a? Integer
		    	status = authorize_url("/#{url}?type=#{param_value.to_i}")
		    else
		    	status = authorize_url("/#{url}")
		   	end
	    else
	        status = authorize_url("/#{url}")
	    end
	    # else
	    #   status = authorize_url("/#{url}")
	    # end

	    if status == false
	      raise CanCan::AccessDenied
	    end
	end
end