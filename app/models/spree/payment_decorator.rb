Spree::Payment.class_eval do

  include Spree::LoyaltyPoints
  include Spree::Payment::LoyaltyPoints

  validates :amount, numericality: { greater_than: 0 }, :if => :by_loyalty_points?
  #validate :redeemable_user_balance, :if => :by_loyalty_points?
  scope :state_not, ->(s) { where('state != ?', s) }

  fsm = self.state_machines[:state]
  fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :notify_paid_order
  fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :redeem_loyalty_points_into_store_credit

  fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :redeem_loyalty_points, :if => :by_loyalty_points?
  fsm.after_transition :from => [:completed], :to => fsm.states.map(&:name) - [:completed] , :do => :return_loyalty_points, :if => :by_loyalty_points?

  private

    def invalidate_old_payments
      order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
        payment.invalidate!
      end unless by_loyalty_points?
    end

    def redeem_loyalty_points_into_store_credit
      if all_payments_completed?
        #When payment is captured, redeem loyalty points if limit is reached
        order.redeem_loyalty_points_in_store_credit order
      end
    end

    def notify_paid_order
      if all_payments_completed?
        #When payment is captured, award loyalty points to customer.
        order.credit_loyalty_points_to_user_for_current_order order
        order.touch :paid_at
      end
    end

    def all_payments_completed?
      order.payments.state_not('invalid').all? { |payment| payment.completed? }
    end

end
