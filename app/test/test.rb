# Creating and Using classes in JRuby
require 'java'


class Employee
  def information
  puts "Name : Amit"
  puts "Age : 21"
  puts "Comapany : RoseIndia"
  end
  def salary
   puts "First Name : Amit"
   puts "Basic Scale : 12000-15000"
   puts "Transport Allowance : 1500"
   puts "Deductions : 2000"
   puts "==========================="
  puts "Total : 24000"
   end
end


# creating new employee object
emp = Employee.new 

# printing employee information
puts " Employee Information List"
puts "#{emp.information}"
# printing employee salary
puts " Employee Salary"
puts "#{emp.salary}"
