require 'rails_helper'

describe OralHistoryItem do
  it "can import item" do
    expected_imported = 2
    total_imported = OralHistoryItem.import({limit: expected_imported})
    expect(total_imported).to eq expected_imported
  end

  it "doesn't reimport duplicate records" do
    total_imported = OralHistoryItem.import({progress: false, limit: 1})
    expect(total_imported).to eq 1
    document_id = OralHistoryItem.fetch_first_id
    record = OralHistoryItem.find_or_new(document_id)
    expect(record.new_record?).to eq false
  end
end