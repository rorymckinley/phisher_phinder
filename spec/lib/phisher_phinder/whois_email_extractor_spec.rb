# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::WhoisEmailExtractor do
  describe 'whois contents contains a single OrgAbuseEmail entry' do
    let(:contents) do
      "OrgTechHandle: XXXX\nOrgTechName:   Person, One\nOrgTechPhone:  +123-4567\nOrgTechEmail:  tech@test.zzz\n" +
        "OrgTechRef:    https://rdap.arin.net/registry/entity/XXXX\n\n" +
        "OrgAbuseHandle: YYYY\nOrgAbuseName:   Person, Two\nOrgAbusePhone:  +1-123-4568\n" +
        "OrgAbuseEmail:  abuse@test.zzz\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/YYYY\n\n" +
        "OrgTechHandle: ZZZZ\nOrgTechName:   Person, Three\nOrgTechPhone:  +1-123-4569\n" +
        "OrgTechEmail:  tech@test.zzz\nOrgTechRef:    https://rdap.arin.net/registry/entity/ZZZ"
    end

    it 'returns an array containing the entry' do
      expect(subject.abuse_contact_emails(contents)).to eql(['abuse@test.zzz'])
    end
  end

  describe 'whois contents contain multiple OrgAbuseEmail entries' do
    let(:contents) do
      "OrgTechHandle: XXXX\nOrgTechName:   Person, One\nOrgTechPhone:  +123-4567\nOrgTechEmail:  tech@test.zzz\n" +
        "OrgTechRef:    https://rdap.arin.net/registry/entity/XXXX\n\n" +
        "OrgAbuseHandle: YYYY\nOrgAbuseName:   Person, Two\nOrgAbusePhone:  +1-123-4568\n" +
        "OrgAbuseEmail:  abuse@test.zzz\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/YYYY\n\n" +
        "OrgTechHandle: ZZZZ\nOrgTechName:   Person, Three\nOrgTechPhone:  +1-123-4569\n" +
        "OrgTechEmail:  tech@test.zzz\nOrgTechRef:    https://rdap.arin.net/registry/entity/ZZZ\n\n" +
        "OrgAbuseHandle: AAAA\nOrgAbuseName:   Person, Four\nOrgAbusePhone:  +1-123-4570\n" +
        "OrgAbuseEmail:  abuse@test.yyy\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/AAAA"
    end

    it 'returns an array containing all the email addresses' do
      expect(subject.abuse_contact_emails(contents)).to eql(['abuse@test.zzz', 'abuse@test.yyy'])
    end
  end

  describe 'whois contents contain duplicated OrgAbuseEmail entries' do
    let(:contents) do
      "OrgTechHandle: XXXX\nOrgTechName:   Person, One\nOrgTechPhone:  +123-4567\nOrgTechEmail:  tech@test.zzz\n" +
        "OrgTechRef:    https://rdap.arin.net/registry/entity/XXXX\n\n" +
        "OrgAbuseHandle: YYYY\nOrgAbuseName:   Person, Two\nOrgAbusePhone:  +1-123-4568\n" +
        "OrgAbuseEmail:  abuse@test.zzz\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/YYYY\n\n" +
        "OrgTechHandle: ZZZZ\nOrgTechName:   Person, Three\nOrgTechPhone:  +1-123-4569\n" +
        "OrgTechEmail:  tech@test.zzz\nOrgTechRef:    https://rdap.arin.net/registry/entity/ZZZ\n\n" +
        "OrgAbuseHandle: AAAA\nOrgAbuseName:   Person, Four\nOrgAbusePhone:  +1-123-4570\n" +
        "OrgAbuseEmail:  abuse@test.yyy\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/AAAA\n\n" +
        "OrgAbuseHandle: BBBB\nOrgAbuseName:   Person, Five\nOrgAbusePhone:  +1-123-4571\n" +
        "OrgAbuseEmail:  abuse@test.zzz\nOrgAbuseRef:    https://rdap.arin.net/registry/entity/BBBB"
    end

    it 'returns an array containing the distinct email addresses' do
      expect(subject.abuse_contact_emails(contents)).to eql(['abuse@test.zzz', 'abuse@test.yyy'])
    end
  end

  describe 'whois contents contains an `Abuse contact line`' do
    let(:contents) do
      "% Information related to '10.0.0.1 - 10.0.0.255'\n\n" +
        "% Abuse contact for '10.0.0.1 - 10.0.0.255' is 'abuse@test.zzz'\n\n" +
        "inetnum:        10.0.0.1 - 10.0.0.255\nnetname:        ZZ-REGISTRY\ncountry:        ZZ"
    end

    it 'returns an array containing the referenced email address' do
      expect(subject.abuse_contact_emails(contents)).to eql(['abuse@test.zzz'])
    end
  end

  describe 'whois contents an abuse@ email address in the contents' do
    let(:contents) do
      "admin-c:        XXX-AFRINIC\nadmin-c:        YYY-AFRINIC\ntech-c:         ZZZ-AFRINIC\n" +
        "tech-c:         AAA-AFRINIC\nnic-hdl:        BBB-AFRINIC\n" +
        "remarks:        ----------------------------------------------------\n" +
        "remarks:        Please contact abuse@test.zzz in case of abuse.\n" +
        "remarks:        ----------------------------------------------------\n" +
        "mnt-by:         XX-ZA\n" +
        "source:         AFRINIC # Filtered"
    end

    it 'returns an array containing the referenced email address' do
      expect(subject.abuse_contact_emails(contents)).to eql(['abuse@test.zzz'])
    end
  end

  describe 'whois contents contains a Registrar Abuse Contact Email entry' do
    let(:contents) do
      "Registrar Registration Expiration Date: 2021-09-27T19:29:52Z\n" +
        "Registrar: Foo\n" +
        "Registrar Abuse Contact Email: contact@test.zzz\n" +
        "Registrar Abuse Contact Phone: +27.1234567\n" +
        "Reseller:\n" +
        "Domain Status: ok https://icann.org/epp#ok"
    end

    it 'returns an array containing the email address' do
      expect(subject.abuse_contact_emails(contents)).to eql(['contact@test.zzz'])
    end
  end

  describe 'the contents do not contain a recognisable pattern' do
    let(:contents) do
      "% Information related to '10.0.0.1 - 10.0.0.255\n\n" +
        "% No abuse contact registered for 10.0.0.1 - 10.0.0.255\n\n" +
        "inetnum:        10.0.0.1 - 10.0.0.255\n" +
        "netname:        foo\n" +
        "descr:          bar\n" +
        "descr:          baz\n" +
        "descr:          buz\n"
    end

    it 'returns an empty array' do
      expect(subject.abuse_contact_emails(contents)).to eql([])
    end
  end
end
