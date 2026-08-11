RSpec.describe Inferno::Jobs do
  let(:job_klass) { Inferno::Jobs::ExecuteTestRun }
  let(:params) { ['test-run-id'] }

  describe '.perform' do
    context 'when force_synchronous is true' do
      it 'runs the job inline and never enqueues it' do
        job_instance = instance_double(job_klass, perform: nil)
        allow(job_klass).to receive_messages(new: job_instance, perform_async: nil, set: nil)

        described_class.perform(job_klass, *params, force_synchronous: true, tags: ['session:abc'])

        expect(job_instance).to have_received(:perform).with(*params)
        expect(job_klass).to_not have_received(:perform_async)
        expect(job_klass).to_not have_received(:set)
      end
    end

    context 'when async_jobs is disabled' do
      it 'runs the job inline and never enqueues it, even if tags are given' do
        job_instance = instance_double(job_klass, perform: nil)
        allow(job_klass).to receive_messages(new: job_instance, perform_async: nil, set: nil)

        described_class.perform(job_klass, *params, tags: ['session:abc'])

        expect(job_instance).to have_received(:perform).with(*params)
        expect(job_klass).to_not have_received(:perform_async)
        expect(job_klass).to_not have_received(:set)
      end
    end

    context 'when async_jobs is enabled' do
      before { stub_const('Inferno::Application', { 'async_jobs' => true }) }

      context 'with tags' do
        it 'enqueues the job tagged via Sidekiq#set' do
          setter = instance_double(Sidekiq::Job::Setter, perform_async: nil)
          allow(job_klass).to receive_messages(set: setter, perform_async: nil)

          described_class.perform(job_klass, *params, tags: ['session:abc', 'run:def'])

          expect(job_klass).to have_received(:set).with(tags: ['session:abc', 'run:def'])
          expect(setter).to have_received(:perform_async).with(*params)
          expect(job_klass).to_not have_received(:perform_async)
        end

        it 'compacts nil tags before enqueuing' do
          setter = instance_double(Sidekiq::Job::Setter, perform_async: nil)
          allow(job_klass).to receive_messages(set: setter, perform_async: nil)

          described_class.perform(job_klass, *params, tags: [nil, 'session:abc'])

          expect(job_klass).to have_received(:set).with(tags: ['session:abc'])
          expect(setter).to have_received(:perform_async).with(*params)
        end
      end

      context 'without tags' do
        it 'enqueues the job without calling set' do
          allow(job_klass).to receive_messages(perform_async: nil, set: nil)

          described_class.perform(job_klass, *params)

          expect(job_klass).to have_received(:perform_async).with(*params)
          expect(job_klass).to_not have_received(:set)
        end
      end

      context 'with an empty tags array' do
        it 'enqueues the job without calling set' do
          allow(job_klass).to receive_messages(perform_async: nil, set: nil)

          described_class.perform(job_klass, *params, tags: [])

          expect(job_klass).to have_received(:perform_async).with(*params)
          expect(job_klass).to_not have_received(:set)
        end
      end
    end
  end
end
