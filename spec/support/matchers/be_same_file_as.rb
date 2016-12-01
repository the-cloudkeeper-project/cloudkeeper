RSpec::Matchers.define :be_same_file_as do |expected|
  match do |actual|
    expect(md5_hash(actual)).to eq(md5_hash(expected))
  end

  failure_message do |actual|
    "expected #{actual} to be the same file as #{expected}\n#{Diffy::Diff.new(actual, expected, source: 'files', context: 3)}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} not to be the same file as #{expected}\n#{Diffy::Diff.new(actual, expected, source: 'files', context: 3)}"
  end

  description do
    "be exactly the same file as #{expected}"
  end

  def md5_hash(file_path)
    Digest::MD5.hexdigest(File.read(file_path))
  end
end
