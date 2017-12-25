module SalesTaxCalculator::Response
  class Base
    def get_lineitem_obj(param = [])
      param.map{|x| LineItem.new(x)} unless param == nil
    end

    def initialize(param = {})
      @messages = param["Messages"]
    end

    def cart_id
      @cart_id
    end

    def lineitems
      @lineitems
    end

    def messages
      @messages
    end

    def has_error?
      false
    end

    def err_description
      @err_description
    end
  end

  class SalesTaxError < Base
    def initialize(param = {})
      @cart_id = param["CartID"]
      @lineitems = get_lineitem_obj(param["CartItemsResponse"])
      @err_description = param["ErrDescription"]
      super
    end

    def has_error?
      true
    end

    def response_code
      all_response_code = []
      @messages.each {|message| all_response_code << message["ResponseType"]}
      all_response_code
    end

    def response_message
      if @err_description.nil?
        full_message = []
        @messages.each { |message| full_message << message["Message"]  }
        full_message.join(", ")
      else
        @err_description
      end
    end

  end

  class Address
    # attr_accessor :address1, :city, :state, :zip5, :err_description
    def initialize(param = {})
      @address1 = param["Address1"]
      @city = param["City"]
      @state = param["State"]
      @zip5 = param["Zip5"]
      @zip4 = param["Zip4"]
      @err_description = param["ErrDescription"]
    end

    def address1
      @address1
    end

    def city
      @city
    end

    def state
      @state
    end

    def zip5
      @zip5
    end

    def zip4
      @zip4
    end

    def err_description
      @err_description
    end
  end

  class LineItem
    def initialize(param = {})
      @lineitem_id = param["CartItemIndex"]
      @tax_amount = param["TaxAmount"]
    end

    def lineitem_id
      @lineitem_id
    end

    def tax_amount
      @tax_amount
    end
  end

  class Authorize < Base

  end

  class Capture < Base

  end

  class Lookup < Base
    def initialize(param = {})
      @cart_id = param["CartID"]
      @lineitems = get_lineitem_obj(param["CartItemsResponse"])
      super
    end

    class << self
      def get_success_response(param = {})
        return new(param)
      end
    end
  end
end
