require 'rspec'

RSpec::Matchers.define :be_valid do
  match {|actual| actual.valid_format?}
end

describe 'New connection head' do
  before :all do
    @server = D3ObyTCPServer.new
  end

  it 'for tramp' do
    head = @server.process_head '[]'
    head.should be_valid
    head.should be_a_kind_of NewConnectionHead
    head.as.should == ''
  end

  it 'for host' do
    head = @server.process_head '[h]'
    head.should be_valid
    head.should be_a_kind_of NewConnectionHead
    head.as.should == 'h'
  end

  it 'for tramp' do
    head = @server.process_head '[g879]'
    head.should be_valid
    head.should be_a_kind_of NewConnectionHead
    head.as.should == 'g879'
  end

  it 'for guest should be invalid' do
    head = @server.process_head '[g]'
    head.should_not be_valid
  end

  it 'should be invalid' do
    head = @server.process_head '[o]'
    head.should_not be_valid
  end
end

describe 'Head' do
  before :all do
    @server = D3ObyTCPServer.new
  end

  it 'should recognize injunction from guest' do
    head = @server.process_head '[1g!16846]'
    head.should be_valid
    head.injunction_id.should be 16846
    head.injunction?.should be_true
    head.as.should == 'g'
  end

  it 'should recognize response' do
    head = @server.process_head '[11g:16846]'
    head.should be_valid
    head.injunction_id.should be 16846
    head.response?.should be_true
  end

  it 'should recognize foreward receiver ids' do
    head = @server.process_head '[1g>15,6899,5,12]'
    head.should be_valid
    head.multi_receivers.should =~ [15,6899,5,12]
    head.foreward?.should be_true
  end

  it 'should recognize backward receivers' do
    head = @server.process_head '[1g<h]'
    head.should be_valid
    head.receiver.should == 'h'
    head.backward?.should be_true
  end

  it 'should recognize minimal message to server' do
    head = @server.process_head '[1]'
    head.should be_valid
    head.receiver.should == 's'
  end

  it 'should be invalid (bad receiver)' do
    head = @server.process_head '[1g>8h]'
    head.should_not be_valid
  end

  it 'should be invalid (bad sender)' do
    head = @server.process_head '[8p]'
    head.should_not be_valid
  end

  it 'should be invalid (include bad characters)' do
    head = @server.process_head '[1g(8]'
    head.should_not be_valid
  end
end