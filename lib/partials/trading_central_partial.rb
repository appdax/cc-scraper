require_relative 'partial'

# Informations about the price of a stock.
class TradingCentralPartial < Partial
  # Initializer of the class.
  #
  # @param [ Hash ] raw The serialized raw data from BNP Paribas.
  #
  # @return [ TradingCentralPartial ]
  def initialize(data)
    super data.fetch(:TradingCentralV1, [])[0] || {}
  end

  # The price where to buy into the stock.
  #
  # @return [ Float ]
  def pivot
    data[:PIVOT]
  end

  # The support values where to buy in.
  #
  # @return [ Array<Float> ]
  def supports
    prune [data[:SUPPORT_1], data[:SUPPORT_2], data[:SUPPORT_3]]
  end

  # The resistance values where to be notified.
  #
  # @return [ Array<Float> ]
  def resistors
    prune [data[:RESISTANCE_1], data[:RESISTANCE_2], data[:RESISTANCE_3]]
  end

  # The short term potential (2-4 weeks).
  #
  # @return [ Hash ] { delta:Int opinion:Int }
  def short_term
    prune delta: data[:DELTA_SHORTTERM], opinion: data[:OPINION_SHORTTERM]
  end

  # The medium term potential (3-6 months).
  #
  # @return [ Hash ] { delta:Int opinion:Int }
  def medium_term
    prune delta: data[:DELTA_MEDIUMTERM], opinion: data[:OPINION_MEDIUMTERM]
  end

  # The date from the last update.
  #
  # @return [ String ] A string in ISO representation.
  def age_in_days
    diff_in_days data[:DATE_ANALYSIS]
  end
end
