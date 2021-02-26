# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Email" do
  describe "a single work" do
    
    before do
      allow(RecordMailer).to receive(:email_record)
        .with(anything, { to: 'ex@example.com', message: 'message' }, hash_including(host: 'www.example.com'))
        .and_return double(deliver: nil)
      document_id = OralHistoryItem.fetch_first_id
      visit "/catalog/#{document_id}"
    end

    it 'has an email link' do
      click_link 'Tools'
      expect(page).to have_content 'Email'
    end

    it 'can be sent via email' do    
      click_link 'Tools'
      click_link 'Email'
      fill_in 'Email:', with: 'ex@example.com'
      fill_in 'Message:', with: 'message'
      click_button 'Send'
      expect(page).to have_content 'Email Sent'
    end
  end  
end