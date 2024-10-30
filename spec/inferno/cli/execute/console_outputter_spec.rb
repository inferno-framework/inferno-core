require_relative '../../../../../lib/inferno/apps/cli/execute/console_outputter'
require_relative 'outputter_spec'

RSpec.describe Inferno::CLI::Execute::ConsoleOutputter do
  let(:instance) { described_class.new }
  let(:options) { { verbose: true } }

  include_examples 'outputter_spec', described_class

  describe '#verbose_print' do
    it 'outputs when verbose is true' do
      expect { instance.verbose_print(options, 'Lorem') }.to output(/Lorem/).to_stdout
    end

    it 'does not output when verbose is false' do
      expect { instance.verbose_print({ verbose: false }, 'Lorem') }.to_not output(/.+/).to_stdout
    end
  end

  describe '#verbose_puts' do
    it 'has output ending with \n with when verbose is true' do
      expect { instance.verbose_puts(options, 'Lorem') }.to output(/Lorem\n/).to_stdout
    end
  end

  describe '#format_tag' do
    let(:suites_repo) { Inferno::Repositories::TestSuites.new }

    let(:suite_all) do
      Class.new(Inferno::TestSuite) do
        id 'mock_suite_id_1'
        short_title 'short'
        title 'title'
      end
    end

    let(:suite_no_short_title) do
      Class.new(Inferno::TestSuite) do
        id 'mock_suite_id_2'
        title 'title'
      end
    end

    let(:suite_id_only) do
      Class.new(Inferno::TestSuite) do
        id 'mock_suite_id_3'
      end
    end

    let(:groups_repo) { Inferno::Repositories::TestGroups.new }

    let(:group_all) do
      Class.new(Inferno::TestGroup) do
        id 'mock_group_id_1'
        short_title 'short'
        title 'title'
      end
    end

    let(:group_no_short_title) do
      Class.new(Inferno::TestGroup) do
        id 'mock_group_id_2'
        title 'title'
      end
    end

    let(:group_no_titles) do
      Class.new(Inferno::TestGroup) do
        id 'mock_group_id_3'
      end
    end

    it "includes a runnable's short_id and short_title if possible" do
      groups_repo.insert(group_all)
      test_result = create(:result, runnable: { test_group_id: group_all.id })

      expect(instance.format_tag(test_result)).to match(group_all.short_id)
      expect(instance.format_tag(test_result)).to match(group_all.short_title)
    end

    it "includes a runnable's short_id and title if no short_title found" do
      groups_repo.insert(group_no_short_title)
      test_result = create(:result, runnable: { test_group_id: group_no_short_title.id })

      expect(instance.format_tag(test_result)).to match(group_no_short_title.short_id)
      expect(instance.format_tag(test_result)).to match(group_no_short_title.title)
    end

    it "includes a runnable's short_id and id if no title/short_title found" do
      groups_repo.insert(group_no_titles)
      test_result = create(:result, runnable: { test_group_id: group_no_titles.id })

      expect(instance.format_tag(test_result)).to match(group_no_titles.short_id)
      expect(instance.format_tag(test_result)).to match(group_no_titles.id)
    end

    it "include's a runnable's short_title if no short_id found" do
      suites_repo.insert(suite_all)
      test_result = create(:result, runnable: { test_suite_id: suite_all.id })

      expect(instance.format_tag(test_result)).to match(suite_all.short_title)
    end

    it "include's a runnable's title if no short_id/short_title found" do
      suites_repo.insert(suite_no_short_title)
      test_result = create(:result, runnable: { test_suite_id: suite_no_short_title.id })

      expect(instance.format_tag(test_result)).to match(suite_no_short_title.title)
    end

    it "include's a runnable's id if no short_id/short_title/title found" do
      suites_repo.insert(suite_id_only)
      test_result = create(:result, runnable: { test_suite_id: suite_id_only.id })

      expect(instance.format_tag(test_result)).to match(suite_id_only.id)
    end
  end

  describe '#format_messages' do
    let(:test_result) { repo_create(:result, message_count: 10) }

    it 'includes all characters' do
      messages = test_result.messages
      formatted_string = instance.format_messages(test_result)

      messages.each do |message|
        expect(formatted_string).to include message.message
      end
    end
  end

  describe '#format_requests' do
    let(:test_result) { repo_create(:result, request_count: 10) }

    it 'includes all status codes' do
      requests = test_result.requests
      formatted_string = instance.format_requests(test_result)

      requests.each do |request|
        expect(formatted_string).to include request.status.to_s
      end
    end
  end

  describe '#format_session_data' do
    let(:data) { [{ name: :url, value: 'https://example.com' }, { name: :token, value: 'SAMPLE_OUTPUT' }] }
    let(:test_result) { create(:result, input_json: JSON.generate(data), output_json: JSON.generate(data)) }

    it 'includes all values for input_json' do
      formatted_string = instance.format_session_data(test_result, :input_json)
      data.each do |data_element|
        expect(formatted_string).to include data_element[:value]
      end
    end

    it 'includes all values for output_json' do
      formatted_string = instance.format_session_data(test_result, :output_json)
      data.each do |data_element|
        expect(formatted_string).to include data_element[:value]
      end
    end
  end

  describe '#format_result' do
    Inferno::Entities::Result::RESULT_OPTIONS.each do |result_option|
      it "can format #{result_option} result type" do
        result = create(:result, result: result_option)
        expect { instance.format_result(result) }.to_not raise_error
      end

      it 'includes result type in return value' do
        result = create(:result, result: result_option)
        expect(instance.format_result(result).upcase).to include result_option.upcase
      end
    end
  end

  describe '#print_color_results' do
    let(:results) { create_list(:random_result, 10) }

    it 'outputs something with verbose false' do
      expect { instance.print_results({ verbose: false }, results) }.to output(/.+/).to_stdout
    end

    it 'outputs something with verbose true' do
      expect { instance.print_results(options, results) }.to output(/.+/).to_stdout
    end
  end
end
