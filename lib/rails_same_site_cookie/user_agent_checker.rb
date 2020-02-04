require 'user_agent_parser'

module RailsSameSiteCookie
  class UserAgentChecker
    PARSER = UserAgentParser::Parser.new

    attr_reader :user_agent

    def user_agent=(user_agent)
      @user_agent_str = user_agent
      @user_agent = user_agent ? PARSER.parse(user_agent) : nil
    end

    def initialize(user_agent=nil)
      @user_agent_str = user_agent
      @user_agent = PARSER.parse(user_agent) if user_agent
    end

    def send_same_site_none?
      return true if user_agent.nil? or @user_agent_str == ''
      return !missing_same_site_none_support?
    end

    private
    def missing_same_site_none_support?
      has_webkit_ss_bug? or drops_unrecognized_ss_cookies?
    end

    def has_webkit_ss_bug?
      is_ios_version?('12') or (is_mac_osx_version?('10','14') and is_safari?)
    end

    def drops_unrecognized_ss_cookies?
      is_buggy_chrome? or is_buggy_uc?
    end

    def is_ios_version?(major)
      user_agent.os.present? && user_agent.os.family == 'iOS' &&
        user_agent.os.version.present? && user_agent.os.version.major == major
    end

    def is_mac_osx_version?(major,minor)
      user_agent.os.present? && user_agent.os.family ==  'Mac OS X' &&
        user_agent.os.version.present?  && user_agent.os.version.major == major &&
        user_agent.os.version.minor == minor
    end

    def is_safari?
      /Safari/.match(user_agent.family)
    end

    def is_buggy_chrome?
      is_chromium_based? and is_chromium_version_between?((51...67))
    end

    def is_buggy_uc?
      is_uc_browser? and not is_uc_version_at_least?(12,13,2)
    end

    def is_chromium_based?
      /Chrom(e|ium)/.match(@user_agent_str)
    end

    def is_chromium_version_between?(range)
      match = /Chrom[^\/]+\/(\d+)[\.\d]*/.match(@user_agent_str)
      return false unless match
      version = match[1].to_i

      range.include?(version)
    end

    def is_uc_browser?
      user_agent.family == 'UC Browser'
    end

    def is_uc_version_at_least?(major,minor,build)
      if user_agent.version.present? && user_agent.version.major.present?
        majorVersion = user_agent.version.major.present? ? user_agent.version.major.to_i : 0
        minorVersion = user_agent.version.minor.present? ? user_agent.version.minor.to_i : 0
        patchVersion = user_agent.version.patch.present? ? user_agent.version.patch.to_i : 0

        if majorVersion == major && minorVersion == minor
          patchVersion >= build
        elsif majorVersion == major
          minorVersion > minor
        else
          majorVersion > major
        end
      end
    end

  end
end
