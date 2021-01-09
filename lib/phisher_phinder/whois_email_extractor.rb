# frozen_string_literal: true

module PhisherPhinder
  class WhoisEmailExtractor
    def abuse_contact_emails(contents)
      if contents =~ /OrgAbuseEmail/
        contents.scan(/OrgAbuseEmail:\s+(\S+)/).flatten.uniq
      elsif contents =~ /Abuse contact for .+? is '([^']+)'/
        [$1]
      elsif contents =~ /Registrar Abuse Contact Email:\s+([\S]+)/
        [$1]
      elsif contents =~ /(abuse@[\S]+)/
        [$1]
      else
        []
      end
    end
  end
end
