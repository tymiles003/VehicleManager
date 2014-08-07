# == Schema Information
#
# Table name: mileages
#
#  id         :integer          not null, primary key
#  miles      :integer
#  vehicle_id :integer
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Mileage < ActiveRecord::Base
  belongs_to :vehicle
  belongs_to :user

  after_create :check_for_upcoming_service

  def check_for_upcoming_service
    due_service = []
    current_services.each do |service|
      mileage_due = service.mileage_at_service + service.service_type.mileage_interval
      due_date = service.date_of_service + service.service_type.month_interval.months
      if miles > (mileage_due)
        due_service << service
      elsif 15.minutes.ago > (due_date)
        due_service << service
      elsif miles > (mileage_due - 200)
        due_service << service
      elsif 15.minutes.ago > (due_date - 10.days)
        due_service << service
      end
    end
    due_service
  end

  private

    def current_services
    	services = ServiceType.all
    	service_list = []
      current = []
    	unless services.empty?
    		services.each do |service|
    			service_list << service.id
    		end
    	end
    	service_list.each do |service|
        current << vehicle.vehicle_services.where("service_type_id = #{service}").order(:created_at).last
      end
      return current
    end
end