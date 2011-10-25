#!/usr/bin/ruby

module GoogleAppsApi #:nodoc:
  module Provisioning
    class Api < GoogleAppsApi::BaseApi
      attr_reader :token


      def initialize(*args)
        super(:provisioning, *args)
      end

      def retrieve_user(user, *args)
        username = user.kind_of?(UserEntity) ? user.id : user
        
        options = args.extract_options!.merge(:username => username)
        request(:retrieve_user, options) 
      end


      def retrieve_all_users(*args)
        options = args.extract_options!
        request(:retrieve_all_users, options)
      end


      def create_user(username, *args)
        options = args.extract_options!      
        options.each { |k,v| options[k] = escapeXML(v)}

        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
        <apps:login userName="#{escapeXML(username)}" 
        password="#{options[:password]}" suspended="false"/>
        <apps:name familyName="#{options[:family_name]}" givenName="#{options[:given_name]}"/>
        </atom:entry>

        DESCXML


        request(:create_user, options.merge(:body => res.strip))
      end

      def move_user_to_orgunit(orgunitname, username, *args)
        options = args.extract_options!
        #username like user@domain
        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <apps:property name="name" value="#{orgunitname}" />
        <apps:property name="description" value="#{orgunitname}" />
        <apps:property name="parentOrgUnitPath" value="" />
        <apps:property name="usersToMove" value="#{username}" />
        </atom:entry>
        
        DESCXML
        
        request(:move_user_to_orgunit, options.merge(:orgunit => orgunitname, :customerid => retrieve_customerid, :debug => true, :body => res.strip))
      end

      def retrieve_customerid(*args)
        options = args.extract_options!
        @customerid ||= request(:retrieve_customerid, options).at_css('entry>id').inner_text.sub("https://apps-apis.google.com/a/feeds/customer/2.0/","")
      end      

      def retrieve_all_orgunits(*args)
        options = args.extract_options!.merge(:customerid => retrieve_customerid)
        request(:retrieve_all_orgunits, options) #.at_css('entry>id').inner_text.sub("https://apps-apis.google.com/a/feeds/customer/2.0/","")
      end      
    
      def update_user(username, *args)
        options = args.extract_options!      
        options.each { |k,v| options[k] = escapeXML(v)}
      
        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
        <apps:name familyName="#{options[:family_name]}" givenName="#{options[:given_name]}"/>
        </atom:entry>
      
        DESCXML
        request(:update_user, options.merge(:username => username, :body => res.strip))
      end


      def delete_user(username, *args)
        options = args.extract_options!.merge(:username => username)
        request(:delete_user, options)
      end

      def update_password(username, *args)
        options = args.extract_options!      
        options.each { |k,v| options[k] = escapeXML(v)}

        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <atom:category scheme="http://schemas.google.com/g/2005#kind"
        term="http://schemas.google.com/apps/2006#user"/>
        <apps:login password="#{options[:password]}" hashFunctionName="#{options[:hash_name]}"/>
        </atom:entry>

        DESCXML
        request(:update_user, options.merge(:username => username, :body => res.strip))
      end
                                                                                                            

      def create_group(groupid, *args)
        options = args.extract_options!      
        options.each { |k,v| options[k] = escapeXML(v)}

        perms = options[:permission] || "Admin"

        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <apps:property name="groupId" value="#{escapeXML(groupid)}"></apps:property>
        <apps:property name="groupName" value="#{options[:name]}"></apps:property>
        <apps:property name="description" value="#{options[:description]}"></apps:property>
        <apps:property name="emailPermission" value="#{perms}"></apps:property>
        </atom:entry>

        DESCXML
        request(:create_group, options.merge(:groupid => groupid, :body => res.strip))
      end

      def retrieve_all_groups(*args)
        options = args.extract_options!
        request(:retrieve_all_groups, options)
      end

      def retrieve_groups_for_user(memberid, *args)
        options = args.extract_options!
        direct = options.has_key?(:direct) ? options[:direct] : false
        request(:retrieve_groups_for_user, options.merge(:memberid => memberid, :direct => direct))
      end

      def update_group(groupid, *args)
        options = args.extract_options!      
        options.each { |k,v| options[k] = escapeXML(v)}

        perms = options[:permission] || "Admin"

        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <apps:property name="groupId" value="#{escapeXML(groupid)}"></apps:property>
        <apps:property name="groupName" value="#{options[:name]}"></apps:property>
        <apps:property name="description" value="#{options[:description]}"></apps:property>
        <apps:property name="emailPermission" value="#{perms}"></apps:property>
        </atom:entry>
        DESCXML
        request(:update_group, options.merge(:body => res.strip))
      end

      def delete_group(groupid, *args)
        options = args.extract_options!.merge(:groupid => groupid)
        request(:delete_group, options)
      end

      def add_user_to_group(groupid, userid, *args)
        options = args.extract_options!

        res = <<-DESCXML
        <?xml version="1.0" encoding="UTF-8"?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:apps="http://schemas.google.com/apps/2006">
        <apps:property name="memberId" value="#{escapeXML(userid)}"/>
        </atom:entry>
        DESCXML
        request(:add_user_to_group, options.merge(:groupid => groupid, :body => res.strip))
      end

      def retrieve_group_members(groupid, *args)
        options = args.extract_options!
        request(:retrieve_group_members, options.merge(:groupid => groupid))
      end

      def retrieve_group_member(groupid, memberid, *args)
        options = args.extract_options!
        request(:retrieve_group_member, options.merge(:groupid => groupid, :memberid => memberid))
      end

      def remove_user_from_group(groupid, memberid, *args)
        options = args.extract_options!
        request(:remove_user_from_group, options.merge(:groupid => groupid, :memberid => memberid))
      end

    end

  end


  class UserEntity < Entity
    attr_accessor :given_name, :family_name, :username, :suspended, :ip_whitelisted, :admin, :change_password_at_next_login, :agreed_to_terms, :quota_limit, :domain, :id

    def initialize(*args)
      options = args.extract_options!
      if (_xml = options[:xml])
        xml = _xml.at_css("entry") || _xml
        @kind = "user"
        @id = xml.at_css("apps|login").attribute("userName").content
        @domain = xml.at_css("id").content.gsub(/^.+\/feeds\/([^\/]+)\/.+$/,"\\1")

        @family_name = xml.at_css("apps|name").attribute("familyName").content
        @given_name = xml.at_css("apps|name").attribute("givenName").content
        @suspended = xml.at_css("apps|login").attribute("suspended").content
        @ip_whitelisted = xml.at_css("apps|login").attribute("ipWhitelisted").content
        @admin = xml.at_css("apps|login").attribute("admin").content
        @change_password_at_next_login = xml.at_css("apps|login").attribute("changePasswordAtNextLogin").content
        @agreed_to_terms = xml.at_css("apps|login").attribute("agreedToTerms").content
        @quota_limit = xml.at_css("apps|quota").attribute("limit").content
      else
        if args.first.kind_of?(String)
          super(:user => args.first)
        else
          super(options.merge(:kind => "user"))
        end
      end
    end
    
    def entity_for_base_calendar
      CalendarEntity.new(self.full_id)
    end
    
    def get_base_calendar(c_api, *args)
      c_api.retrieve_calendar_for_user(self.entity_for_base_calendar, self, *args)
    end
    
    def get_calendars(c_api, *args)
      c_api.retrieve_calendars_for_user(self, *args)
    end
  end

  class OrgUnitEntity < Entity
    attr_accessor :name, :orgunitpath

    def initialize(*args)
      options = args.extract_options!
      if (_xml = options[:xml])
        xml = _xml.at_css("entry") || _xml
         xml.css("apps|property").each do |x|
           if x.attribute("name").to_s == "name"
             @name = x.attribute("value").to_s
           end
           if x.attribute("name").to_s == "orgUnitPath"
             @orgunitpath = x.attribute("value").to_s
           end
         end
      end
    end
    
  end

  class GroupEntity < Entity
    attr_accessor :id, :name, :permission, :description

    def initialize(*args)
      options = args.extract_options!
      if (_xml = options[:xml])
        xml = _xml.at_css("entry") || _xml
        xml.css("apps|property").each do |x|
          case x.attribute("name").to_s
          when "groupId"
            @id = x.attribute("value").to_s
          when "groupName"
            @name = x.attribute("value").to_s
          when "emailPermission"
            @permission = x.attribute("value").to_s
          when "description"
            @description = x.attribute("value").to_s
          end
        end
      end
    end

  end

  class GroupMemberEntity < Entity
    attr_accessor :id, :type, :direct

    def initialize(*args)
      options = args.extract_options!
      if (_xml = options[:xml])
        xml = _xml.at_css("entry") || _xml
        xml.css("apps|property").each do |x|
          case x.attribute("name").to_s
          when "memberId"
            @id = x.attribute("value").to_s
          when "memberType"
            @type = x.attribute("value").to_s
          when "directMember"
            @direct = x.attribute("value").to_s
          end
        end
      end
    end

  end

end
