# encoding: utf-8

require 'spec_helper'

describe Griddler::Email, 'body formatting' do
  it 'uses the html field and sanitizes it when text param missing' do
    body = <<-EOF
      <p>Hello.</p><span>-- REPLY ABOVE THIS LINE --</span><p>original message</p>
    EOF

    expect(raw_body_from_email(html: body)).to eq body
  end

  it 'uses the html field and sanitizes it when text param is empty' do
    body = <<-EOF
      <p>Hello.</p><span>-- REPLY ABOVE THIS LINE --</span><p>original message</p>
    EOF

    expect(raw_body_from_email(html: body, text: '')).to eq body
  end

  it 'handles invalid utf-8 bytes in html' do
    expect(raw_body_from_email(html: "Hell\xC0.")).to eq 'HellÀ.'
  end

  it 'handles invalid utf-8 bytes in text' do
    expect(raw_body_from_email(text: "Hell\xF6.")).to eq 'Hellö.'
  end

  it 'handles valid utf-8 bytes in html' do
    expect(raw_body_from_email(html: "Hell\xF1.")).to eq 'Hellñ.'
  end

  it 'handles valid utf-8 bytes in text' do
    expect(raw_body_from_email(text: "Hell\xF2.")).to eq 'Hellò.'
  end

  it 'handles valid utf-8 char in html' do
    expect(raw_body_from_email(html: 'Hellö.')).to eq 'Hellö.'
  end

  it 'handles valid utf-8 char in text' do
    expect(raw_body_from_email(text: 'Hellö.')).to eq 'Hellö.'
  end

  it 'does not remove invalid utf-8 bytes if charset is set' do
    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'iso-8859-1'
    }

    expect(raw_body_from_email({ text: 'Helló.' }, charsets)).to eq 'Helló.'
  end

  it 'does not remove embedded [cid] images if they come as html' do
    image_tag = '<img src="cid:ii_15d764b442ac37dd" alt="Inline image 1">'
    expect(raw_body_from_email(html: image_tag)).to eq image_tag
  end

  it 'does not remove embedded [data] images if they come as html' do
    image_tag = '<img src="data:data:image/jpeg;base64,/9j/4S/+RXhpZgAATU0AKgAAAAgACAESAAMAENkDZ5u8/" alt="Inline image 1">'
    expect(raw_body_from_email(html: image_tag)).to eq image_tag
  end

  it 'handles everything on one line' do
    body = <<-EOF
      Hello. On 01/12/13, Tristan <email@example.com> wrote: -- REPLY ABOVE THIS LINE -- or visit your website to respond.
    EOF
    expect(raw_body_from_email(text: body)).to eq body
  end


  it 'handles "On [date] [soandso] <email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "On [date] [soandso]\n<email@example.com> wrote:" format' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan\n <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "> On [date] [soandso] <email@example.com> wrote:" format' do
    body = <<-EOF.strip_heredoc
      Hello.

      > On 10 janv. 2014, at 18:00, Tristan <email@example.com> wrote:
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
      >
    EOF
    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "From: email@email.com" format' do
    body =
    <<-EOF
      Hello.

      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "*From:* email@email.com" format' do
    body = <<-EOF
      Hello.

      *From:* bob@example.com
      *Sent:* Today
      *Subject:* Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "-----Original Message-----" format' do
    body = <<-EOF
      Hello.

      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "-----Original Message-----" format without a preceding body' do
    body = <<-EOF
      -----Original Message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "-----Original message-----" case insensitively' do
    body = <<-EOF
      Hello.

      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "-----Original message-----" case insensitively without a preceding body' do
    body = <<-EOF
      -----Original message-----
      From: bob@example.com
      Sent: Today
      Subject: Awesome report.

      Check out this report!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "[date] [soandso] <email@example>" format' do
    body = <<-EOF
      2013/12/15 Bob Example <bob@example.com>
      > Check out this report.
      >
      > It's pretty cool.
      >
      > Thanks, Tristan
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles "-- REPLY ABOVE THIS LINE --" format' do
    body = <<-EOF
      Hello.

      -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'removes > in "> -- REPLY ABOVE THIS LINE --" ' do
    body = <<-EOF
      Hello.

      > -- REPLY ABOVE THIS LINE --
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'removes any non-content things above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      On 2010-01-01 12:00:00 Tristan wrote:

      > -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'removes any iphone things above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      Sent from my iPhone

      > -- REPLY ABOVE THIS LINE --

      Hey!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'should remove any signature above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'should trim signature with non-breaking space after hyphens' do
    body = <<-EOF
      Hello.

      --\xC2\xA0
      Mr. Smith
      CEO, company
      t: 6174821300
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'should remove any signature without space above -- REPLY ABOVE THIS LINE --' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'allows paragraphs to begin with "On"' do
    body = <<-EOF
      On the counter.

      On Tue, Sep 30, 2014 at 9:13 PM Tristan <email@example.com> wrote:
      > Where's that report?
      >
      > Thanks, Tristen
    EOF

    clean_body = <<-EOF
      On the counter.

      On Tue, Sep 30, 2014 at 9:13 PM Tristan  wrote:
      > Where's that report?
      >
      > Thanks, Tristen
    EOF

    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'properly handles a json charsets' do
    body = <<-EOF
      Hello.

      --
      Mr. Smith
      CEO, company
      t: 6174821300

      > -- REPLY ABOVE THIS LINE --

      > Hey!
    EOF

    charsets = {
      to: 'UTF-8',
      html: 'utf-8',
      subject: 'UTF-8',
      from: 'UTF-8',
      text: 'utf-8'
    }

    expect(raw_body_from_email({ text: body }, charsets)).to eq body
  end

  it 'should preserve empty lines' do
    body = "Hello.\n\nWhat's up?"
    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'preserves blockquotes' do
    body = "> Hello.\n\n>another line"
    expect(raw_body_from_email(text: body)).to eq body
  end

  it 'handles empty body values' do
    expect(raw_body_from_email(text: '')).to eq ''
  end

  it 'handles missing body keys' do
    expect(raw_body_from_email(text: nil)).to eq ''
  end

  def email_from_body(raw_body, charsets = {})
    raw_body.each do |format, text|
      text.encode!(charsets[format]) if charsets[format]
    end

    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com',
      charsets: charsets.to_json
    }

    raw_body.select! do |format, text|
      text.force_encoding('utf-8') if text
    end

    params.merge!(raw_body)

    Griddler::Email.new(params)
  end

  def body_from_email(raw_body, charsets = {})
    email_from_body(raw_body, charsets).body
  end

  def clean_body_from_email(raw_body, charsets = {})
    email_from_body(raw_body, charsets).clean_body
  end

  def raw_body_from_email(raw_body, charsets = {})
    email_from_body(raw_body, charsets).raw_body
  end
end

describe Griddler::Email, 'multipart emails' do
  it 'allows raw access to text and html bodies' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    expect(email.raw_html).to eq '<b>hello there</b>'
    expect(email.raw_text).to eq 'hello there'
  end

  it 'uses text as raw_body if both text and html are present' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: 'hello there'
    )
    expect(email.raw_body).to eq 'hello there'
  end

  it 'uses text as raw_body' do
    email = email_with_params(
      text: 'hello there'
    )
    expect(email.raw_body).to eq 'hello there'
  end

  it 'uses html as raw_body if text is not present' do
    email = email_with_params(
      html: '<b>hello there</b>'
    )
    expect(email.raw_body).to eq '<b>hello there</b>'
  end

  it 'uses html as raw_body if text is empty' do
    email = email_with_params(
      html: '<b>hello there</b>',
      text: ''
    )
    expect(email.raw_body).to eq '<b>hello there</b>'
  end

  def email_with_params(params)
    params = {
      to: ['hi@example.com'],
      from: 'bye@example.com'
    }.merge(params)

    Griddler::Email.new(params)
  end
end

describe Griddler::Email, 'extracting email headers' do
  it 'extracts header names and values as a hash' do
    header_name = 'Arbitrary-Header'
    header_value = 'Arbitrary-Value'
    header = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq header_value
  end

  it 'handles a hash being submitted' do
    header = {
      "X-Mailer" => "Airmail (271)",
      "Mime-Version" => "1.0"
    }
    headers = header_from_email(header)
    expect(headers["X-Mailer"]).to eq("Airmail (271)")
  end

  it 'cleans invalid UTF-8 bytes from a hash when it is submitted' do
    header_name = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header = { header_name => header_value }
    headers = header_from_email(header)

    expect(headers[header_name]).to eq "invalid utf-8 bytes are ÀÁõúþÿ."
  end

  it 'deeply cleans invalid UTF-8 bytes from a hash when it is submitted' do
    header_name = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header = { header_name => { "a" => [header_value] } }
    headers = header_from_email(header)

    expect(headers[header_name]).to eq({ "a" => ["invalid utf-8 bytes are ÀÁõúþÿ."] })
  end

  it 'handles no matched headers' do
    headers = header_from_email('')
    expect(headers).to eq({})
  end

  it 'handles nil headers' do
    headers = header_from_email(nil)
    expect(headers).to eq({})
  end

  it 'handles invalid utf-8 bytes in headers' do
    header_name = 'Arbitrary-Header'
    header_value = "invalid utf-8 bytes are \xc0\xc1\xf5\xfa\xfe\xff."
    header = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq "invalid utf-8 bytes are ÀÁõúþÿ."
  end

  it 'handles valid utf-8 bytes in headers' do
    header_name = 'Arbitrary-Header'
    header_value = "valid utf-8 bytes are ÀÁõÿ."
    header = "#{header_name}: #{header_value}"

    headers = header_from_email(header)
    expect(headers[header_name]).to eq "valid utf-8 bytes are ÀÁõÿ."
  end

  def header_from_email(header)
    params = {
      headers: header,
      to: ['hi@example.com'],
      from: 'bye@example.com',
      text: ''
    }

    email = Griddler::Email.new(params)
    email.headers
  end
end

describe Griddler::Email, 'extracting email addresses' do
  before do
    @address_components = {
      full: 'Bob <bob@example.com>',
      email: 'bob@example.com',
      token: 'bob',
      host: 'example.com',
      name: 'Bob',
    }
    @full_address= @address_components[:full]
    @bcc_address_components = {
      full: 'Johny <johny@example.com>',
      email: 'johny@example.com',
      token: 'johny',
      host: 'example.com',
      name: 'Johny',
    }
    @full_bcc_address= @bcc_address_components[:full]
  end

  it 'extracts the name' do
    email = Griddler::Email.new(
      to: [@full_address],
      from: @full_address,
    )
    expect(email.to).to eq [@address_components.merge(name: 'Bob')]
  end

  it 'handles normal e-mail address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: [@address_components[:email]],
      from: @full_address
    )
    expected = @address_components.merge(
      full: @address_components[:email],
      name: nil,
    )
    expect(email.to).to eq [expected]
    expect(email.from).to eq @address_components

  end

  it 'handles empty names' do
    email = Griddler::Email.new(
      text: 'hi',
      to: [' '],
      from: @full_address
    )
    expected = {
      token: nil,
      host: nil,
      email: '',
      full: ' ',
      name: nil
    }
    expect(email.to).to eq [expected]
    expect(email.from).to eq @address_components
  end

  it 'returns the BCC email' do
    email = Griddler::Email.new(
        text: 'hi',
        to: [@address_components[:email]],
        from: @full_address,
        bcc: [@full_bcc_address],
    )
    expect(email.bcc).to eq [@bcc_address_components]
  end

  it 'handles new lines' do
    email = Griddler::Email.new(text: 'hi', to: ["#{@full_address}\n"],
      from: "#{@full_address}\n")
    expected = @address_components.merge(full: "#{@full_address}\n")
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles angle brackets around address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["<#{@address_components[:email]}>"],
      from: "<#{@address_components[:email]}>"
    )
    expected = @address_components.merge(
      full: "<#{@address_components[:email]}>",
      name: nil)
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles name and angle brackets around address' do
    email = Griddler::Email.new(
      text: 'hi',
      to: [@full_address],
      from: @full_address
    )
    expect(email.to).to eq [@address_components]
    expect(email.from).to eq @address_components
  end

  it 'handles multiple e-mails, with priority to the bracketed' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["fake@example.com <#{@address_components[:email]}>"],
      from: "fake@example.com <#{@address_components[:email]}>"
    )
    expected = @address_components.merge(
      full: "fake@example.com <#{@address_components[:email]}>",
      name: 'fake@example.com'
    )

    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end

  it 'handles invalid UTF-8 characters' do
    email = Griddler::Email.new(
      text: 'hi',
      to: ["\xc0\xc1\xf5\xfa\xfe\xff #{@full_address}"],
      from: "\xc0\xc1\xf5\xfa\xfe\xff #{@full_address}")
    expected = @address_components.merge(
      full: "ÀÁõúþÿ Bob <bob@example.com>",
      name: "ÀÁõúþÿ Bob"
    )
    expect(email.to).to eq [expected]
    expect(email.from).to eq expected
  end
end

describe Griddler::Email, 'extracting email subject' do
  before do
    @address = 'bob@example.com'
    @subject = 'A very interesting email'
  end

  it 'handles normal characters' do
    email = Griddler::Email.new(
      to: [@address],
      from: @address,
      subject: @subject,
    )
    expect(email.subject).to eq @subject
  end

  it 'handles invalid UTF-8 characters' do
    email = Griddler::Email.new(
      to: [@address],
      from: @address,
      subject: "\xc0\xc1\xf5\xfa\xfe\xff #{@subject}",
    )
    expected = "ÀÁõúþÿ #{@subject}"
    expect(email.subject).to eq expected
  end
end

describe Griddler::Email, 'extracting email addresses from CC field' do
  before do
    @address = 'bob@example.com'
    @cc = 'Charles Conway <charles+123@example.com>'
  end

  it 'uses the cc from the adapter' do
    email = Griddler::Email.new(to: [@address], from: @address, cc: [@cc], headers: @headers)
    expect(email.cc).to eq [{
      token: 'charles+123',
      host: 'example.com',
      email: 'charles+123@example.com',
      full: 'Charles Conway <charles+123@example.com>',
      name: 'Charles Conway',
    }]
  end

  it 'returns an empty array when no CC address is added' do
    email = Griddler::Email.new(to: [@address], from: @address)
    expect(email.cc).to be_empty
  end
end

describe Griddler::Email, 'with custom configuration' do
  context 'with multiple recipients in to field' do
    it 'includes all of the emails' do
      recipients = ['caleb@example.com', '<joel@example.com>', 'Swift <swift@example.com>']
      params = { to: recipients, from: 'ralph@example.com', text: 'hi guys' }

      email = Griddler::Email.new(params)

      expect(email.to.map { |to| to[:full] }).to eq recipients
    end
  end
end

describe Griddler::Email, 'with envelope set' do
  context 'with envelope from payload' do
    it 'passes envelope to the object' do
      recipients = ['caleb@example.com', '<joel@example.com>']
      envelope = "{\"to\":[\"caleb@example.com\",\"joel@example.com\"],\"from\":\"ralph@example.com\"}"
      params = { to: recipients, from: 'ralph@example.com', text: 'hi guys', envelope: envelope }

      email = Griddler::Email.new(params)

      expect(email.envelope).to eq envelope
    end
  end
end

describe Griddler::Email, 'with charsets set' do
  context 'with charsets from payload' do
    it 'passes charsets to the object' do
      recipients = ['caleb@example.com', '<joel@example.com>']
      charsets = { to: 'UTF-8', cc: 'UTF-8', filename: 'UTF-8', subject: 'UTF-8', from: 'UTF-8', text: 'UTF-8' }.to_json
      params = { to: recipients, from: 'ralph@example.com', text: 'hi guys', charsets: charsets}

      email = Griddler::Email.new(params)

      expect(email.charsets).to eq charsets
    end
  end
end
