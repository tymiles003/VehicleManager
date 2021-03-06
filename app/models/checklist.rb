# == Schema Information
#
# Table name: checklists
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  comments          :text
#  created_at        :datetime
#  updated_at        :datetime
#  checklist_type_id :integer
#  properties        :text
#  user_id           :integer
#  vehicle_id        :integer
#

class Checklist < ActiveRecord::Base
  belongs_to :checklist_type
  belongs_to :vehicle
  belongs_to :user
  serialize :properties, Hash

  validate :validate_properties

  after_save :update_current_mileage
  after_save :check_for_failures

  def validate_properties
    checklist_type.fields.each do |field|
      if field.required? && properties[field.name].blank?
        errors.add field.name, "must not be blank"
      end
    end
    if self.properties["Current Mileage"].to_i < Vehicle.find(self.vehicle_id).current_mileage
      errors.add :current_mileage, "inputed cannot be less than previous mileage. \(#{Vehicle.find(self.vehicle_id).current_mileage} miles\)"
    end
    if self.properties["Current Mileage"].to_i > (Vehicle.find(self.vehicle_id).current_mileage + 3000)
      errors.add :current_mileage, "inputed cannot be 3000 miles more than previous mileage. \(#{Vehicle.find(self.vehicle_id).current_mileage} miles\)"
    end
  end

  private 

  def update_current_mileage
    miles = self.properties["Current Mileage"].to_i
    if miles > 1
      vehicle = Vehicle.find(self.vehicle_id)
      if vehicle.current_mileage < miles
        vehicle.current_mileage = miles
        vehicle.user_id = self.user_id
        vehicle.save
      else
        errors.add :current_mileage, "inputed cannot be less than previous mileage."
      end
    end
  end

  def check_for_failures
    failures = []
    self.properties.each do |property|
      if property[1] == "fail"
        failures << property[0]
      end
    end
    if failures.length > 0
      ServiceMailer.notify_mechanic(user, self.vehicle, failures).deliver
    end
  end
end
