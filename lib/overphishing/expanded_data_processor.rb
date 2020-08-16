module Overphishing
  class ExpandedDataProcessor
    def process(mail)
      {
        linked_content: mail.hypertext_links.map { |l| lookup_content(l) },
        mail: mail
      }
    end

    private

    def lookup_content(link)
      require 'net/http'

      response = Net::HTTP.get_response(link.href)

      base_response = {
        href: link.href,
        link_text: link.text,
        status: response.code.to_i,
        body: nil,
        links_within_body: []
      }

      base_response.merge(response.is_a?(Net::HTTPOK) ? body_data(response) : {})
    end

    def body_data(response)
      {
        body: response.body,
        links_within_body: response.body.scan(/https?:\/\/[a-z0-9\/._?=,&#!*~();:@+$%\[\]-]+/i)
      }
    end
  end
end
