RSpec.describe EventPartial do
  let!(:events) { EventsPartial.new(json) }
  let!(:event) { events.first }

  before { Timecop.freeze(Time.utc(2016, 4, 18)) }

  context 'when EventsV1 is present' do
    let(:raw) { IO.read('spec/fixtures/facebook.json') }
    let(:json) { JSON.parse(raw, symbolize_names: true)[0] }

    describe '#type' do
      it { expect(event.type).to eq('AGM') }
    end

    describe '#name' do
      it { expect(event.name).to eq('Ordentliche Hauptversammlung') }
    end

    describe '#occurs_in' do
      it { expect(event.occurs_in).to eq(59) }
    end
  end
end
