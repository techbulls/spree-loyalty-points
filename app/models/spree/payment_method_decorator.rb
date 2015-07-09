Spree::PaymentMethod.class_eval do

  scope :loyalty_points_type, -> { where(type: 'Spree::PaymentMethod::StoreCredit') }

  def self.loyalty_points_id_included?(method_ids)
    loyalty_points_type.where(id: method_ids).size != 0
  end

end