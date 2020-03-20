/**
* @description Bird Eye Rest Data Format
**/
public with sharing class BirdEyeData {


	/**
	* @description Bird Eye Customer check in
	**/
	public class CustomerCheckIn{
		public String name;
		public String emailId;
		public String phone;
		public Integer smsEnabled;
		public BirdEyeData.CheckInConfig checkinConfig;
		public List<BirdEyeData.Employee> employees;
		
		/**
		* @description Constructor
		**/
		public CustomerCheckIn(Contact contact, Integer emailTemplateId){
			this.name = contact.FirstName+' '+contact.LastName;
			this.emailId = contact.Email;
			this.phone = contact.MobilePhone;
			this.smsEnabled = 1;
			this.checkinConfig = new BirdEyeData.CheckInConfig();
			this.checkinConfig.reviewEmailTemplateId = emailTemplateId;
			this.employees = new List<BirdEyeData.Employee>();
			BirdEyeData.Employee employee = new BirdEyeData.Employee();
			employee.emailId = contact.Email;
			this.employees.add(employee);
		}
	}

	/**
	* @description Check in config
	**/
	public class CheckInConfig{
		public Integer reviewEmailTemplateId;
	}

	/**
	* @description Employee
	**/
	public class Employee{
		public String emailId;
	}
}