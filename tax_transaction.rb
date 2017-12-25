class SalesTaxCalculator::TaxTransaction
  include ActiveModel::Model
  @@items = []
  attr_accessor :destination_address, :origin_address, :order_id, :lineitems, :cart_id, :delivered_by_seller, :customer_id, :lookup_response, :date_authorized, :date_captured, :authorize_response, :capture_response, :authorize_with_capture_response

  validates :customer_id, presence: true
  validates :destination_address, presence: true
  validates :origin_address, presence: true
  validates :lineitems, presence: true

  def items
    self.lineitems = @@items
    self.lineitems
  end

  def self.proc_method(url, &proc)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["content-type"] = 'application/json'
    yield(request, http)
  end

  def proc_method(url, &proc)
    if self.valid?
      self.class.proc_method(url, &proc)
    else
      self.errors
    end
  end

  def calculate
    calculate_tax_block = Proc.new do |request, http|
      request.body = transaction_parameter.to_json
      response = http.request(request)
      response_hash = JSON.parse(response.read_body) || {}
      if response_hash["ResponseType"] == 3
        self.lookup_response = SalesTaxCalculator::Response::Lookup.get_success_response(response_hash)
        self.cart_id = response_hash["CartID"]
        return true
      else
        self.lookup_response = SalesTaxCalculator::Response::SalesTaxError.new(response_hash)
        return false
      end
    end
    proc_method(SalesTaxCalculator::TAX_AMOUNT_LOOKUP_URL, &calculate_tax_block)
  end

  def authorize_transaction
    authorize_txn_block = Proc.new do |request, http|
      request.body = order_authorized_parameter.to_json
      response = http.request(request)
      response_hash = JSON.parse(response.read_body) || {}
      if response_hash["ResponseType"] == 3
        self.authorize_response = SalesTaxCalculator::Response::Authorize.new(response_hash)
        # self.cart_id = self.lookup_response.cart_id
        return true
      else
        self.authorize_response = SalesTaxCalculator::Response::SalesTaxError.new(response_hash)
        return false
      end
    end
    proc_method(SalesTaxCalculator::AUTHORIZE_ORDER_URL, &authorize_txn_block)
  end

  def capture_transaction
    capture_txn_block = Proc.new do |request, http|
      capture_parameters = Hash.new
      capture_parameters.merge!(SalesTaxCalculator.api_parameter)
      capture_parameters["orderID"] = order_id
      request.body = capture_parameters.to_json
      response = http.request(request)
      response_hash = JSON.parse(response.read_body) || {}
      if response_hash["ResponseType"] == 3
        self.capture_response = SalesTaxCalculator::Response::Capture.new(response_hash)
        # self.cart_id = self.lookup_response.cart_id
        return true
      else
        self.capture_response = SalesTaxCalculator::Response::SalesTaxError.new(response_hash)
        return false
      end
    end
    proc_method(SalesTaxCalculator::CAPTURE_URL, &capture_txn_block)
  end

  def authorize_with_capture_transaction
    authorize_with_capture_txn_block = Proc.new do |request, http|
      order_authorized_parameter_with_capture = order_authorized_parameter.merge!("dateCaptured":date_captured)
      request.body = order_authorized_parameter_with_capture.to_json
      response = http.request(request)
      response_hash = JSON.parse(response.read_body) || {}
      if response_hash["ResponseType"] == 3
        self.authorize_with_capture_response = SalesTaxCalculator::Response::Authorize.new(response_hash)
        # self.cart_id = self.lookup_response.cart_id
        return true
      else
        self.authorize_with_capture_response = SalesTaxCalculator::Response::SalesTaxError.new(response_hash)
        return false
      end
    end
    proc_method(SalesTaxCalculator::AUTHORIZED_WITH_CAPTURED_URL, &authorize_with_capture_txn_block)
  end

  def order_authorized_parameter
    authorization_hash = Hash.new
    authorization_hash.merge!(SalesTaxCalculator.api_parameter)
    authorization_hash["customerID"] = customer_id
    authorization_hash["cartID"] = cart_id
    authorization_hash["orderID"] = order_id
    authorization_hash["dateAuthorized"] = date_authorized
    authorization_hash
  end

  def transaction_parameter
    transaction = Hash.new
    transaction.merge!(SalesTaxCalculator.api_parameter)
    transaction["origin"] = origin_address
    transaction["destination"] = destination_address
    transaction["cartItems"] = lineitems.map(&:to_hash)
    transaction["customerID"] = customer_id
    transaction
  end
end
