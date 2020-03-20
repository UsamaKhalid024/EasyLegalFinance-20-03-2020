/*
 * This is a constants class used to track all fixed field items used accross the development
 */
public class Constants {
	
    // Used in PaymentController
    public static final String PAYMENT_MODE_AMOUNT = 'Amount';
    public static final String PAYMENT_MODE_DATE = 'Date';
    public static final String VIEW_PAYMENTS_FIELD_SET = 'ViewPayments';
    
    // Used in PaymentHelper, DrawdownHelper
    public static final String[] PAYMENT_SCHEDULE_MODIFIABLE_STATUSES = New String[]{'Scheduled', 'Rejected'};
    public static final String[] PAYMENT_SCHEDULE_IN_PROCESS_STATUSES = New String[]{'Pre Send Validation', 'Approved to Send', 'Sent to Bank', 'Processed by Bank'};
    public static final String[] PAYMENT_SCHEDULE_PROCESSED_STATUSES = New String[]{'Drawdown Created', 'Closed'};
    public static final String PAYMENT_SCHEDULED_STATUS = 'Scheduled';
    public static final String PAYMENT_SCHEDULED_TYPE = 'Scheduled Facility';
    public static final String PAYMENT_PAID_STATUS = 'Paid'; 

    // Used in DrawdownHelper
    public static final String FACILITY_LOAN = 'Facility Loan';

    // Bird eye 
    public static final String HTTP_POST = 'POST';
    public static final String ELFI_BUSINESS_UNIT = 'ELFI';
    public static final String RHINO_BUSINESS_UNIT = 'Rhino';
}