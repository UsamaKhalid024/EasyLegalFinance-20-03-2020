/**
*    @description : EFT File Header
**/
public with sharing class EFTFileHeader {
    
    private String eftFileHeader;
    private EFT_File_Setting__c eftFileSetting;
    public String eftFileNumber = '0001';
    public Date dueDate {get; set;}


    /**
    *    @description : Constructor
    **/
    public EFTFileHeader(Date dueDate){
        this.eftFileSetting = EFT_File_Setting__c.getInstance();
        this.dueDate = dueDate;
    }

    /**
    *    @description : Constructor
    **/
    public EFTFileHeader(Date dueDate, String eftFileNumber){
        this.eftFileSetting = EFT_File_Setting__c.getInstance();
        this.dueDate = dueDate;
        this.eftFileNumber = eftFileNumber;
    }

    /**
    *    @description : Method to set originator Id number
    **/
    private void setOriginatorIdNumber(){
        List<User> usersList = [SELECT Id, EFT_Originator_Id__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(!usersList.isEmpty()) {
            if (usersList[0].EFT_Originator_Id__c.length() != 10) {
                throw new EFTFileException(null, '', 'User has an invalid EFT Originator Id. Please have an admin update your user with a 10 character originator Id from the bank.');
            }
            this.eftFileHeader += usersList[0].EFT_Originator_Id__c;
        } else {
            throw new EFTFileException(null, '', 'Must be run as a User with a valid EFT Originator Id.');
        }
    }

    /**
    *    @description : Method to set transaction type
    **/
    private void setTransactionType(String transactionType){
        this.eftFileHeader += transactionType;
    }

    /**
    *    @description : Method to set CPA code
    **/
    private void setCPAcode(String cpaCode){
        this.eftFileHeader += cpaCode;
    }

    /**
    *    @description : Method to set CPA code
    **/
    private void setDueDate(){
        this.eftFileHeader += DateTime.newInstance(this.dueDate,Time.newInstance(0,0,0,0)).format('ddMMyy');
    }

    /**
    *    @description : Method to set Originator Short Name
    **/
    private void setOriginatorShortName(){
        this.eftFileHeader += EFTHelper.formatString(this.eftFileSetting.Originator_Short_Name__c, ' ', 15, 'left');
    }

    /**
    *    @description : Method to set Transit Number for returns
    **/
    private void setTransitNumberForReturns(){
        if (this.eftFileSetting.Transit_Number_For_Returns__c.length() != 9) {
            throw new EFTFileException(null, '', 'Invalid Transit Number for Returns. Please have an admin update your eftFileSettings.');
        }
        this.eftFileHeader += this.eftFileSetting.Transit_Number_For_Returns__c;
    }

    /**
    *    @description : Method to set Account Number for returns
    **/
    private void setAccountNumberForReturns(){
        if (this.eftFileSetting.Account_Number_For_Returns__c.length() != 11) {
            throw new EFTFileException(null, '', 'Invalid Account Number for Returns. Please have an admin update your eftFileSettings.');
        }
        this.eftFileHeader += this.eftFileSetting.Account_Number_For_Returns__c + ' ';
    }

    /**
    *    @description : Method to set File Creation Number
    **/
    private void setFileCreationNumber(){
        this.eftFileHeader += this.eftFileNumber; //'0001'; // This needs to increment through 0001-9999 and before rolling over to 0001
    }

    /**
    *    @description : Method to add filler spaces
    **/
    private void addFillerSpaces(){
        this.eftFileHeader += EFTHelper.formatString('', '', 19, 'left');
    }

    /**
    *    @description : Constructor
    **/
    public String getFileHeaderAsString(){
        this.eftFileHeader = 'H';
        setOriginatorIdNumber();
        this.setTransactionType('C');
        this.setCPAcode('351');
        this.setDueDate();
        this.setOriginatorShortName();
        this.setTransitNumberForReturns();
        this.setAccountNumberForReturns();
        this.setFileCreationNumber();
        this.addFillerSpaces();

        if (this.eftFileHeader.length() != 80) {
            throw new EFTFileException(null, '', 'Invalid Header Generated. Please have a developer look into this: "' + this.eftFileHeader + '"' );
        }
        return this.eftFileHeader;
    }
}