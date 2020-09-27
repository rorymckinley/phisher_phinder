# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::HeaderValueParser do

  describe 'quoted-printable encoding' do
    it 'parses a value that has the iso-8859-1 character set' do
      expect(
        subject.parse('  =?iso-8859-1?q?=C4 ')
      ).to eql('Ä')
      expect(
        subject.parse('  =?iso-8859-1?q?=C4 =?iso-8859-1?q?=DF =?iso-8859-1?q?=C7  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?q?=C4 =?ISO-8859-1?q?=DF =?ISO-8859-1?q?=C7  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?iso-8859-1?Q?=C4 =?iso-8859-1?Q?=DF =?iso-8859-1?Q?=C7  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?Q?=C4 =?ISO-8859-1?Q?=DF =?ISO-8859-1?Q?=C7  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?Q?=C4 =?iso-8859-1?Q?=DF =?ISO-8859-1?q?=C7  ')
      ).to eql('ÄßÇ')
    end

    it 'parses a value that has the windows-1251 character set' do
      expect(
        subject.parse(
          ' =?windows-1251?q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? '
        )
      ).to eql('Реклама не дает результат?')
      expect(
        subject.parse(
          '=?windows-1251?q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? ' +
          '=?windows-1251?q?foo=20bar  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?WINDOWS-1251?q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? ' +
          '=?WINDOWS-1251?q?foo=20bar  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?windows-1251?Q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? ' +
          '=?windows-1251?Q?foo=20bar  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?WINDOWS-1251?Q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? ' +
          '=?WINDOWS-1251?Q?foo=20bar  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?WINDOWS-1251?Q?=D0=E5=EA=EB=E0=EC=E0=20=ED=E5=20=E4=E0=E5=F2=20=F0=E5=E7=F3=EB=FC=F2=E0=F2? ' +
          '=?windows-1251?Q?foo=20bar  '
        )
      ).to eql('Реклама не дает результат?foo bar')
    end

    it 'parses a value that has the UTF-8 character set' do
      expect(
        subject.parse('  =?utf-8?q?fo=C3=B5 ')
      ).to eql('foõ')
      expect(
        subject.parse('  =?utf-8?q?fo=C3=B5 =?utf-8?q?=C3=9F=C3=A6=C3=9E =?utf-8?q?fo=C4=89   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?q?fo=C3=B5 =?UTF-8?q?=C3=9F=C3=A6=C3=9E =?UTF-8?q?fo=C4=89   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?utf-8?Q?fo=C3=B5 =?utf-8?Q?=C3=9F=C3=A6=C3=9E =?utf-8?Q?fo=C4=89   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?Q?fo=C3=B5 =?UTF-8?Q?=C3=9F=C3=A6=C3=9E =?UTF-8?Q?fo=C4=89   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?Q?fo=C3=B5 =?utf-8?q?=C3=9F=C3=A6=C3=9E =?utf-8?Q?fo=C4=89   ')
      ).to eql('foõßæÞfoĉ')
    end
  end

  describe 'base64 encoding' do
    it 'parses a value that has the iso-8859-1 character set' do
      expect(
        subject.parse('  =?iso-8859-1?b?xA== ')
      ).to eql('Ä')
      expect(
        subject.parse('  =?iso-8859-1?b?xA== =?iso-8859-1?b?3w== =?iso-8859-1?b?xw==  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?b?xA== =?ISO-8859-1?b?3w== =?ISO-8859-1?b?xw==  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?iso-8859-1?B?xA== =?iso-8859-1?B?3w== =?iso-8859-1?B?xw==  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?B?xA== =?ISO-8859-1?B?3w== =?ISO-8859-1?B?xw==  ')
      ).to eql('ÄßÇ')
      expect(
        subject.parse('  =?ISO-8859-1?B?xA== =?iso-8859-1?b?3w== =?iso-8859-1?B?xw==  ')
      ).to eql('ÄßÇ')
    end

    it 'parses a value that has the windows-1251 character set' do
      expect(
        subject.parse(
          ' =?windows-1251?b?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8= '
        )
      ).to eql('Реклама не дает результат?')
      expect(
        subject.parse(
          '=?windows-1251?b?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8= ' +
          '=?windows-1251?b?Zm9vIGJhcg==  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?WINDOWS-1251?b?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8= ' +
          '=?WINDOWS-1251?b?Zm9vIGJhcg==  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?windows-1251?B?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8= ' +
          '=?windows-1251?B?Zm9vIGJhcg==  '
        )
      ).to eql('Реклама не дает результат?foo bar')
      expect(
        subject.parse(
          '=?WINDOWS-1251?B?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8= ' +
          '=?WINDOWS-1251?b?Zm9vIGJhcg==  '
        )
      ).to eql('Реклама не дает результат?foo bar')
    end

    it 'parses a value that has the UTF-8 character set' do
      expect(
        subject.parse('  =?utf-8?b?Zm/DtQ== ')
      ).to eql('foõ')
      expect(
        subject.parse('  =?utf-8?b?Zm/DtQ== =?utf-8?b?w5/DpsOe =?utf-8?b?Zm/EiQ==   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?b?Zm/DtQ== =?UTF-8?b?w5/DpsOe =?UTF-8?b?Zm/EiQ==   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?utf-8?B?Zm/DtQ== =?utf-8?B?w5/DpsOe =?utf-8?B?Zm/EiQ==   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?B?Zm/DtQ== =?UTF-8?B?w5/DpsOe =?UTF-8?B?Zm/EiQ==   ')
      ).to eql('foõßæÞfoĉ')
      expect(
        subject.parse('  =?UTF-8?B?Zm/DtQ== =?utf-8?B?w5/DpsOe =?utf-8?b?Zm/EiQ==   ')
      ).to eql('foõßæÞfoĉ')
    end
  end

  it 'returns the passed in value sans padding if there is no encoding' do
    expect(subject.parse(' foo  bar baz    ')).to eql 'foo  bar baz'
  end
end
