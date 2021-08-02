# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecordMailer do
  before do
    allow(described_class).to receive(:default).and_return(from: 'no-reply@projectblacklight.org')
    SolrDocument.use_extension(Blacklight::Document::Email)
    document = SolrDocument.new(id: "123456", format: ["book"], title_display: "The horn", language_display: "English", author_display: "Janetzky, Kurt")
    @documents = [document]
  end

  describe "email" do
    before do
      details = { to: 'test@test.com', message: "This is my message" }
      @email = described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
    end

    it "receives the TO paramater and send the email to that address" do
      expect(@email.to).to include 'test@test.com'
    end

    it "starts the subject w/ Item Record:" do
      expect(@email.subject).to match /^Item Record:/
    end

    it "puts the title of the item in the subject" do
      expect(@email.subject).to match /The horn/
    end

    it "has the correct from address (w/o the port number)" do
      expect(@email.from).to include "no-reply@projectblacklight.org"
    end

    it "prints out the correct body" do
      expect(@email.body).to match /Title: The horn/
      expect(@email.body).to match /Author: Janetzky, Kurt/
      expect(@email.body).to match /projectblacklight.org/
    end

    it "uses https URLs when protocol is set" do
      details = { to: 'test@test.com', message: "This is my message" }
      @https_email = described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
      expect(@https_email.body).to match %r{https://projectblacklight.org/}
    end
  end
end