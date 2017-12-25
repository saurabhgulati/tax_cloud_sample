module SalesTaxCalculator
  VERIFY_ADDRESS_URL = "https://api.taxcloud.com/1.0/TaxCloud/VerifyAddress"
  TAX_AMOUNT_LOOKUP_URL = "https://api.taxcloud.com/1.0/TaxCloud/LookUp"
  AUTHORIZE_ORDER_URL = "https://api.taxcloud.com/1.0/TaxCloud/Authorized"
  CAPTURE_URL = "https://api.taxcloud.com/1.0/TaxCloud/Captured"
  AUTHORIZED_WITH_CAPTURED_URL = "https://api.taxcloud.com/1.0/TaxCloud/AuthorizedWithCapture"

  def self.api_parameter
    params = Hash.new
    params["apiLoginID"] = ENV["tax_cloud_login_id"]
    params["apiKey"] = ENV["tax_cloud_api_key"]
    params
  end

end

require 'tax_cloud/address'
require 'tax_cloud/lineitem'
require 'tax_cloud/tax_transaction'
require 'tax_cloud/response'

module Calc
  def tax_calculation_callbacks
    self.class_eval do
      extend ActiveModel::Callbacks
      define_model_callbacks :calculate_tax,              only: [:before, :after]
      define_model_callbacks :authorize,                  only: [:before, :after]

      attr_accessor :taxable_destination_address, :taxable_origin_address, :taxable_lineitems, :taxable_order_id, :taxable_cart_id, :taxable_delivered_by_seller, :taxable_customer_id, :taxable_response, :taxable_date_authorized, :taxable_authorize_response, :taxable_date_captured, :taxable_capture_response, :taxable_address_response, :taxable_authorize_with_capture_response

      def calculate_tax
        if self.valid?
          run_callbacks :calculate_tax do
            transaction = initialize_tax_transaction
            result = transaction.calculate
            self.taxable_response = transaction.lookup_response
            self.taxable_cart_id = transaction.cart_id
            return result
          end
        else
          return false
        end
      end

      def authorize_taxable_order(with_capture = false)
        if self.valid?
          run_callbacks :calculate_tax do
            transaction = initialize_tax_transaction
            unless with_capture
              res = transaction.authorize_transaction
              self.taxable_authorize_response = transaction.authorize_response
            else
              transaction.date_captured = taxable_date_captured
              res = transaction.authorize_with_capture_transaction
              self.taxable_authorize_with_capture_response = transaction.authorize_with_capture_response
            end
            res
          end
        else
          return false
        end
      end

      def capture_taxable_order
        if self.valid?
          transaction = initialize_tax_transaction
          res = transaction.capture_transaction
          self.taxable_capture_response = transaction.capture_response
          res
        else
          return false
        end
      end

      def verify_address
        if self.valid?
          address = self.taxable_destination_address
          res = address.verify
          self.taxable_address_response = address.response
          res
        else
          return false
        end
      end

      def initialize_tax_transaction
        transaction = SalesTaxCalculator::TaxTransaction.new.tap do |transaction|
          transaction.order_id = taxable_order_id
          transaction.cart_id = taxable_cart_id
          transaction.customer_id = taxable_customer_id
          transaction.destination_address = taxable_destination_address
          transaction.origin_address = taxable_origin_address
          transaction.lineitems = taxable_lineitems
          transaction.date_authorized = taxable_date_authorized
        end
        transaction
      end

    end
  end
end

# To use this lib with model then add following lines in model
# extend Calc
# tax_calculation_callbacks
# example
# origin = SalesTaxCalculator::Address.new(address1: "sdada", address2: "345345", city: "ZY", state: "NY", zip5: "10036")
# destination = SalesTaxCalculator::Address.new(address1: "sdada", address2: "345345", city: "ZY", state: "NY", zip5: "10036")
# transaction = SalesTaxCalculator::TaxTransaction.new
# transaction.origin_address = origin
# transaction.destination_address = destination
# transaction.items << SalesTaxCalculator::LineItem.new(qty: "5", price: 10, lineitem_id: 100)
# transaction.items << SalesTaxCalculator::LineItem.new(qty: "3", price: 20, lineitem_id: 101)
# transaction.customer_id = "any_cust_id"
# transaction.calculate
#
