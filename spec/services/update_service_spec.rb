require_relative '../../app/services/update_service'
require 'med_installer'

RSpec.describe UpdateService do
  context 'when already running an update' do
    let(:redis) { double() }
    let(:prepare) { double('PrepareNewData') }
    let(:index) { double('IndexNewData') }
    subject(:service) {
      UpdateService.new(redis: redis, prepare_command: prepare, index_command: index)
    }

    it 'reports an update is active' do
      expect(redis).to receive(:get).with('mec.update_id').and_return(1)
      expect(service.active?).to be true
    end

    describe 'processing a corpus update' do
      it 'aborts with a lockout error' do
        corpus_update = double()

        expect(redis).to receive(:get).with('mec.update_id').and_return(1)
        expect {
          service.process(corpus_update)
        }.to raise_error(UpdateService::AlreadyUpdatingError)
      end
    end
  end

  context 'when not already running an update' do
    let(:redis) { double('Redis') }
    let(:prepare) { double('PrepareNewData') }
    let(:index) { double('IndexNewData') }
    subject(:service) {
      UpdateService.new(
        redis: redis,
        prepare_command: prepare,
        index_command: index
      )
    }

    it 'reports an update is not active' do
      expect(redis).to receive(:get).with('mec.update_id').and_return(nil)

      expect(service.active?).to be false
    end

    describe 'processing a corpus update' do
      let(:corpus_update) { double('CorpusUpdate', id: 2) }
      let(:uploaded_file) { double('Shrine::UploadedFile') }

      before(:each) do
        allow(redis).to receive(:get).with('mec.update_id').and_return(nil)
        allow(redis).to receive(:set)
        allow(redis).to receive(:del)
        allow(corpus_update).to receive(:corpus).and_return(uploaded_file)
        allow(uploaded_file).to receive(:download) do |*args, &block|
          File.open("spec/fixtures/tiny-set.zip", "r") do |file|
            block.call(file)
          end
        end
        allow(prepare).to receive(:call)
        allow(index).to receive(:call)
      end

      it 'locks with the update ID' do
        expect(redis).to receive(:set).with('mec.update_id', 2)
        service.process(corpus_update)
      end

      it 'prepares the data from the zip file' do
        expect(prepare).to receive(:call).with(zipfile: "spec/fixtures/tiny-set.zip")
        service.process(corpus_update)
      end

      it 'indexes the unpacked corpus' do
        expect(index).to receive(:call).with(force: true)
        service.process(corpus_update)
      end

      it 'unlocks the update ID' do
        expect(redis).to receive(:del).with('mec.update_id')
        service.process(corpus_update)
      end
    end
  end
end
