# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::Parser do
  describe '#parse' do
    def build_parser_double(klass, key)
      double = instance_double(klass)
      allow(double).to receive(:parse) do |args|
        args ? {key => :output} : {key => :nil_output}
      end
      double
    end
    let(:by_parser) do
      build_parser_double(PhisherPhinder::MailParser::ReceivedHeaders::ByParser, :by)
    end
    let(:for_parser) do
      build_parser_double(PhisherPhinder::MailParser::ReceivedHeaders::ForParser, :for)
    end
    let(:from_parser) do
      build_parser_double(PhisherPhinder::MailParser::ReceivedHeaders::FromParser, :from)
    end
    let(:starttls_parser) do
      build_parser_double(PhisherPhinder::MailParser::ReceivedHeaders::StarttlsParser, :starttls)
    end
    let(:timestamp_parser) do
      build_parser_double(PhisherPhinder::MailParser::ReceivedHeaders::TimestampParser, :time)
    end
    let(:classifier) do
      instance_double(PhisherPhinder::MailParser::ReceivedHeaders::Classifier, classify: {partial: true})
    end

    subject do
      described_class.new(
        by_parser: by_parser,
        for_parser: for_parser,
        from_parser: from_parser,
        starttls_parser: starttls_parser,
        timestamp_parser: timestamp_parser,
        classifier: classifier
      )
    end

    describe 'parsing components' do
      it 'partial header with `by` and `for` components' do
        expect(by_parser).to receive(:parse).with('by 2002:a4a:d031:0:0:0:0:0 with SMTP id w17csp2701290oor ')
        expect(for_parser).to receive(:parse).with('for anotherdummy@test.com')
        expect(from_parser).to receive(:parse).with(nil)
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with(' Sat, 25 Apr 2020 22:14:08 -0700 (PDT)')

        header_parts = [
          'by 2002:a4a:d031:0:0:0:0:0 with SMTP id w17csp2701290oor for anotherdummy@test.com;',
          ' Sat, 25 Apr 2020 22:14:08 -0700 (PDT)'
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header with `from` and `by` components' do
        expect(from_parser).to receive(:parse).with('from also.made.up ([10.0.0.4])')
        expect(by_parser).to receive(:parse).with(' by fuzzy.fake.com Fuzzy Corp with SMTP id 3gJek488nka743gKRkR2nY')
        expect(for_parser).to receive(:parse).with(nil)
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with('Sat, 25 Apr 2020 22:14:05 -0700')

        header_parts = [
          'from also.made.up ([10.0.0.4]) ',
          'by fuzzy.fake.com Fuzzy Corp with SMTP id 3gJek488nka743gKRkR2nY;',
          'Sat, 25 Apr 2020 22:14:05 -0700',
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header with `from` component in parentheses and `by` component' do
        expect(from_parser).to receive(:parse).with('(from root@localhost)')
        expect(by_parser).to receive(:parse).with(' by still.dodgy.host.com (8.14.7/8.14.7/Submit) id 05QDRrso001911')
        expect(for_parser).to receive(:parse).with(nil)
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with(nil)

        header_parts = [
          '(from root@localhost) by still.dodgy.host.com (8.14.7/8.14.7/Submit) id 05QDRrso001911'
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header with `from` component' do
        expect(from_parser).to receive(:parse).with('from still.not.real.com (another.dodgy.host.com. 10.0.0.6)')
        expect(by_parser).to receive(:parse).with(nil)
        expect(for_parser).to receive(:parse).with(nil)
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with(nil)

        header_parts = [
          'from still.not.real.com (another.dodgy.host.com. 10.0.0.6)'
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header - by with userid' do
        expect(from_parser).to receive(:parse).with(nil)
        expect(by_parser).to receive(:parse).with('by probably.spam.sender (Postfix, from userid 0) id 095A71BA8')
        expect(for_parser).to receive(:parse).with(nil)
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with(' Mon,  7 Sep 2020 16:48:12 +0300 (MSK)')

        header_parts = [
          'by probably.spam.sender (Postfix, from userid 0) ',
          'id 095A71BA8; Mon,  7 Sep 2020 16:48:12 +0300 (MSK)'
        ]

        subject.parse(header_parts.join)
      end

      it 'full header with TLS' do
        expect(from_parser).to receive(:parse).with('from probably.not.real.com ([10.0.0.3])')
        expect(by_parser).to receive(:parse).with(
          ' by mx.google.com with ESMTPS id u23si16237783eds.526.2020.06.26.06.27.53 '
        )
        expect(for_parser).to receive(:parse).with('for <mannequin@test.com>')
        expect(starttls_parser).to receive(:parse).with(
          ' (version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128)'
        )
        expect(timestamp_parser).to receive(:parse).with('Sat, 25 Apr 2020 22:14:06 -0700')

        header_parts = [
          'from probably.not.real.com ([10.0.0.3]) ',
          'by mx.google.com with ESMTPS id u23si16237783eds.526.2020.06.26.06.27.53 ',
          'for <mannequin@test.com> ',
          '(version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128);',
          'Sat, 25 Apr 2020 22:14:06 -0700'
        ]

        subject.parse(header_parts.join)
      end

      it 'full header without TLS' do
        expect(from_parser).to receive(:parse).with('from not.real.com (my.dodgy.host.com. [10.0.0.5])')
        expect(by_parser).to receive(:parse).with(
          ' by mx.google.com (8.14.7/8.14.7) with ESMTP id b201si8173212pfb.88.2020.04.25.22.14.05 ',
        )
        expect(for_parser).to receive(:parse).with('for <dummy@test.com>')
        expect(starttls_parser).to receive(:parse).with(nil)
        expect(timestamp_parser).to receive(:parse).with(' Sat, 25 Apr 2020 22:14:04 -0700 (PDT)')

        header_parts = [
          'from not.real.com (my.dodgy.host.com. [10.0.0.5]) ',
          'by mx.google.com (8.14.7/8.14.7) with ESMTP id b201si8173212pfb.88.2020.04.25.22.14.05 ',
          'for <dummy@test.com>; ',
          'Sat, 25 Apr 2020 22:14:04 -0700 (PDT)'
        ]

        subject.parse(header_parts.join)
      end

      it 'full header without TLS upper case ID' do
        expect(from_parser).to receive(:parse).with('from not.real.com ([10.0.0.1])')
        expect(by_parser).to receive(:parse).with(' by baz.host (foo bar baz) with SMTP ID 702 ')
        expect(for_parser).to receive(:parse).with('for <dummy@test.com>')

        header_parts = [
          'from not.real.com ([10.0.0.1]) ',
          'by baz.host (foo bar baz) with SMTP ID 702 ',
          'for <dummy@test.com>; ',
          'Mon, 24 Aug 2020 06:15:49 -0700 (PDT)'
        ]

        subject.parse(header_parts.join)
      end

      it 'full header with TLS between from and by' do
        expect(from_parser).to receive(:parse).with('from not.real.com (unknown [10.0.0.1])')
        expect(by_parser).to receive(:parse).with('by foo.bar (Postfix) with ESMTPS id 51B365400F ')
        expect(for_parser).to receive(:parse).with('for <dummy@test.com>')
        expect(starttls_parser).to receive(:parse).with(
          ' (using TLSv1.2 with cipher ECDHE-RSA-AES256-GCM-SHA384 (256/256 bits)) ' +
          '(No client certificate requested) '
        )
        expect(timestamp_parser).to receive(:parse).with(' Mon, 24 Aug 2020 06:15:48 -0700 (PDT)')

        header_parts = [
          'from not.real.com (unknown [10.0.0.1]) ',
          '(using TLSv1.2 with cipher ECDHE-RSA-AES256-GCM-SHA384 (256/256 bits)) ',
          '(No client certificate requested) ',
          'by foo.bar (Postfix) with ESMTPS id 51B365400F ',
          'for <dummy@test.com>; ',
          'Mon, 24 Aug 2020 06:15:48 -0700 (PDT)'
        ]

        subject.parse(header_parts.join)
      end

      it 'full header (internal routing?)' do
        expect(from_parser).to receive(:parse).with('from root ')
        expect(by_parser).to receive(:parse).with(
          'by spam.test.zzz with local-generated (Exim 4.92) (envelope-from <is.this.real.zzz>) id 1kIXad-0006OQ-VE '
        )
        expect(for_parser).to receive(:parse).with('for dummy@test.com')

        header_parts = [
          'from root by spam.test.zzz with local-generated (Exim 4.92) ',
          '(envelope-from <is.this.real.zzz>) ',
          'id 1kIXad-0006OQ-VE ',
          'for dummy@test.com; ',
          'Wed, 16 Sep 2020 15:35:16 +0200'
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header with a HELO' do
        expect(from_parser).to receive(:parse).with(
          'from probably.not.real (HELO foo) ([10.0.0.1]) '
        )
        expect(by_parser).to receive(:parse).with('by recipient.zzz with ESMTP')
        expect(timestamp_parser).to receive(:parse).with(' 10 Sep 2020 08:55:25 +1000')

        header_parts = [
          'from probably.not.real (HELO foo) ([10.0.0.1]) ',
          'by recipient.zzz with ESMTP; 10 Sep 2020 08:55:25 +1000',
        ]

        subject.parse(header_parts.join)
      end

      it 'partial header with from and by no IP data provided', :aggregate_failures do
        expect(from_parser).to receive(:parse).with(
          'from probably.not.real (HELO foo) () '
        )
        expect(by_parser).to receive(:parse).with('by recipient.zzz with SMTP')
        expect(timestamp_parser).to receive(:parse).with(' Sat, 26 Sep 2020 20:44:35 +0200')

        header_parts = [
          'from probably.not.real (HELO foo) () ',
          'by recipient.zzz with SMTP; Sat, 26 Sep 2020 20:44:35 +0200'
        ]

        subject.parse(header_parts.join)
      end

      it 'TLS partial via frontend transport' do
        expect(from_parser).to receive(:parse).with('from probably.not.real (10.0.0.1)')
        expect(by_parser).to receive(:parse).with(
          ' by recipient.zzz (10.10.10.10) with Microsoft SMTP Server ' +
          '(version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 1.2.3.4 ' +
          'via Frontend Transport'
        )
        expect(starttls_parser).to receive(:parse).with(
          ' by recipient.zzz (10.10.10.10) with Microsoft SMTP Server ' +
          '(version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 1.2.3.4 ' +
          'via Frontend Transport'
        )
        expect(timestamp_parser).to receive(:parse).with(' Fri, 4 Sep 2020 06:16:15 +0000')

        header_parts = [
          'from probably.not.real (10.0.0.1) ',
          'by recipient.zzz (10.10.10.10) with Microsoft SMTP Server ',
          '(version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 1.2.3.4 ',
          'via Frontend Transport; Fri, 4 Sep 2020 06:16:15 +0000'
        ]

        subject.parse(header_parts.join)
      end

      it 'mangled and rearranged header' do
        expect(from_parser).to receive(:parse).with('from localhost (127.0.0.1)')
        expect(by_parser).to receive(:parse).with(' by recipient.zzz id SSP82XUF8U4ERPFZGJN4K1M20 ')
        expect(for_parser).to receive(:parse).with('for < victim@test.com >')
        expect(timestamp_parser).to receive(:parse).with(
          ' Sun, 04 Oct 2020 00:36:09 -0400 -+00:00 -0400 (EST) ' +
          '(envelope-from < ""Please respond" <DDYVOWO@overpol.com>" <admin@recipient.zzz> >)'
        )

        header_parts = [
          'from localhost (127.0.0.1) ',
          'by recipient.zzz id SSP82XUF8U4ERPFZGJN4K1M20 ',
          'for < victim@test.com >; ',
          'Sun, 04 Oct 2020 00:36:09 -0400 -+00:00 -0400 (EST) ',
          '(envelope-from < ""Please respond" <DDYVOWO@overpol.com>" <admin@recipient.zzz> >)'
        ]

        subject.parse(header_parts.join)
      end

      it 'classifies a header based on its values' do
        expect(classifier).to receive(:classify).with(
          {by: :output, for: :output, from: :output, starttls: :output, time: :output}
        )

        header_parts = [
          'from probably.not.real.com ([10.0.0.3]) ',
          'by mx.google.com with ESMTPS id u23si16237783eds.526.2020.06.26.06.27.53 ',
          'for <mannequin@test.com> ',
          '(version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128);',
          'Sat, 25 Apr 2020 22:14:06 -0700'
        ]

        subject.parse(header_parts.join)
      end
    end

    describe 'parsing output' do
      it 'includes the output from all the parsers for complete records' do
        header_parts = [
          'from probably.not.real.com ([10.0.0.3]) ',
          'by mx.google.com with ESMTPS id u23si16237783eds.526.2020.06.26.06.27.53 ',
          'for <mannequin@test.com> ',
          '(version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128);',
          'Sat, 25 Apr 2020 22:14:04 -0700'
        ]

        output = subject.parse(header_parts.join)

        expect(output).to eql({
          by: :output,
          from: :output,
          for: :output,
          partial: true,
          starttls: :output,
          time: :output,
        })
      end

      it 'can provide partial output if the record is a partial record' do
        header_parts = [
          'from still.not.real.com (another.dodgy.host.com. 10.0.0.6)'
        ]

        output = subject.parse(header_parts.join)

        expect(output).to eql({
          by: :nil_output,
          for: :nil_output,
          from: :output,
          starttls: :nil_output,
          time: :nil_output,
          partial: true,
        })
      end
    end
  end
end
