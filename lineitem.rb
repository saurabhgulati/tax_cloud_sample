class SalesTaxCalculator::LineItem
  include ActiveModel::Model

  attr_accessor :qty, :price, :tic, :lineitem_sku, :lineitem_id

  def to_hash
    item = Hash.new
    item[:Qty] = qty
    item[:Price] = price
    item[:TIC] = tic
    item[:ItemId] = lineitem_sku
    item[:Index] = lineitem_id
    item
  end
end
