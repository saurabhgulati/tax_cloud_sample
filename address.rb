class SalesTaxCalculator::Address
  include ActiveModel::Model
  attr_accessor :address1, :address2, :city, :state, :country, :zip5, :zip4, :response

  validates :address1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip5, presence: true

  def verify
    verify_address_block = Proc.new do |request, http|
      request.body = extract_json_address.to_json
      response = http.request(request)
      address_response_hash = JSON.parse response.read_body || {}
      if address_response_hash["ErrNumber"].to_i == 0
        self.response = SalesTaxCalculator::Response::Address.new(address_response_hash)
        return true
      else
        self.response = SalesTaxCalculator::Response::SalesTaxError.new(address_response_hash)
        return false
      end
    end
    SalesTaxCalculator::TaxTransaction.proc_method(SalesTaxCalculator::VERIFY_ADDRESS_URL, &verify_address_block)
  end

  def extract_json_address
    addr = Hash.new
    addr.merge!(SalesTaxCalculator.api_parameter)
    addr["Address1"] = address1
    addr["Address2"] = address2
    addr["City"] = city
    addr["State"] = state
    addr["Zip5"] = zip5
    addr["Zip4"] = zip4
    addr
  end
end
