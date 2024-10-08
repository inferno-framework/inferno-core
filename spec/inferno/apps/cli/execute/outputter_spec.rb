RSpec.shared_examples "outputter_spec" do |outputter_class|
  it 'responds to print_start_message' do
    expect(outputter_class.new).to respond_to(:print_start_message)
  end

  it 'responds to print_around_run' do
    expect(outputter_class.new).to respond_to(:print_around_run)
  end

  it 'method print_around_run yields' do
    expect do
      expect { |b| outputter_class.new.print_around_run({}, &b) }.to yield_control
    end.to output(/.?/).to_stdout_from_any_process # required to prevent output in rspec
  end

  it 'responds to print_results' do
    expect(outputter_class.new).to respond_to(:print_results)
  end

  it 'responds to print_end_message' do
    expect(outputter_class.new).to respond_to(:print_end_message)
  end

  it 'responds to print_error' do
    expect(outputter_class.new).to respond_to(:print_error)
  end

  it 'returns an object whose print_error does not raise exception nor exit' do
    expect do
      expect { outputter_class.new.print_error({}, StandardError.new('my error')) }.to_not raise_error
    end.to output(/.?/).to_stdout # required to prevent output in rspec
  end
end
