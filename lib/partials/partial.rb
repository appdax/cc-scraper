
# Informations about a partial aspect of a stock.
class Partial
  # Initializer of the class.
  #
  # @param [ Hash ] raw The serialized raw data from BNP Paribas.
  def initialize(data)
    @data = data
  end

  attr_reader :data

  # If there are informations within the provided data.
  #
  # @return [ Boolean ] A true value means availability.
  def available?
    @data && @data.any?
  end

  # Call method equal to key and return the value.
  #
  # @param [Symbol] Method name.
  #
  # @return [ Object ]
  def [](key)
    public_send key
  rescue
    nil
  end
end
