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
      base_output = {
        href: link.href,
        link_text: link.text,
        content_requested: true,
        response: nil,
        error: nil
      }

      if link.supports_retrieval?
        require 'net/http'

        begin
          response = Net::HTTP.get_response(link.href)

          if response.is_a?(Net::HTTPOK)
            base_output.merge({response: response_with_body(response)})
          else
            base_output.merge(response: response_status_only(response))
          end
        rescue => e
          base_output.merge(
            error: {
              class: e.class,
              message: e.message
            }
          )
        end
      else
        base_output.merge(content_requested: false)
      end
    end

    def response_with_body(response)
      {
        status: response.code.to_i,
        body: response.body,
        links_within_body: response.body.scan(/https?:\/\/[a-z0-9\/._?=,&#!*~();:@+$%\[\]-]+/i)
      }
    end

    def response_status_only(response)
      {
        status: response.code.to_i,
        body: nil,
        links_within_body: []
      }
    end
  end
end
