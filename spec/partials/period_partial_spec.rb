RSpec.describe PeriodPartial do
  let(:history) { HistoryPartial.new(json, '') }
  let(:period) { history.first }

  before { Timecop.freeze(Time.utc(2016, 4, 18)) }

  context 'when HistoryV1 is present' do
    let(:raw) { IO.read('spec/fixtures/facebook.json') }
    let(:json) { JSON.parse(raw, symbolize_names: true)[0] }

    describe '#first' do
      it { expect(period.first).to eq(97.049) }
    end

    describe '#last' do
      it { expect(period.last).to eq(97.803) }
    end

    describe '#high' do
      it { expect(period.high).to eq(97.91) }
    end

    describe '#low' do
      it { expect(period.low).to eq(96.021) }
    end

    describe '#age' do
      it { expect(period.age).to eq(0) }
    end

    describe '#volatility' do
      it { expect(period.volatility).to eq(1.93) }
    end
  end

  context 'when HistoryV1 is missing' do
    let(:json) { {} }
    let(:period) { described_class.new json }

    describe '#first' do
      it { expect { period.first }.to_not raise_error }
      it { expect(period.first).to be_nil }
    end

    describe '#last' do
      it { expect { period.last }.to_not raise_error }
      it { expect(period.last).to be_nil }
    end

    describe '#high' do
      it { expect { period.high }.to_not raise_error }
      it { expect(period.high).to be_nil }
    end

    describe '#low' do
      it { expect { period.low }.to_not raise_error }
      it { expect(period.low).to be_nil }
    end

    describe '#age' do
      it { expect { period.age }.to_not raise_error }
      it { expect(period.age).to be_nil }
    end

    describe '#volatility' do
      before do
        allow(period).to receive(:high).and_return 0
        allow(period).to receive(:low).and_return 0
      end

      it { expect { period.volatility }.to_not raise_error }
      it { expect(period.volatility).to be_nil }
    end
  end
end
