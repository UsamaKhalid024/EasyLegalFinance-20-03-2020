/**
*    @description : EFT File Detail
**/
public with sharing class EFTFileDetail {
    
    private String eftFileDetail;
    // private Account account;
    private Bank_Account__c bankAccount;
    private Date dueDate;
    private Decimal amount;
    private String referenceNumber;
    
    /**
    *    @description : Constructor
    **/
    public EFTFileDetail(Bank_Account__c bankAccount, Date dueDate, Decimal amount, String referenceNumber){
        this.bankAccount = bankAccount;
        this.dueDate = dueDate;
        this.amount = amount;
        this.referenceNumber = referenceNumber;
    }

    /**
    *    @description : Method to set payee type
    **/
    private void setPayeeName(){
        this.eftFileDetail += EFTHelper.formatString(this.bankAccount.Name, '', 23, 'right');
    }
    
    /**
    *    @description : Method to set CPA code
    **/
    private void setDueDate(){
        this.eftFileDetail += DateTime.newInstance(this.dueDate,Time.newInstance(0,0,0,0)).format('ddMMyy');
    }
    
    /**
    *    @description : Method to set Originator Reference number
    **/
    private void setOriginatorReferenceNumber(){
        this.eftFileDetail += EFTHelper.formatString(referenceNumber, '', 19, 'left');
    }
    
    /**
    *    @description : Method to set Transit number
    **/
    private void setTransitNumber(){
        if (this.bankAccount.Bank__c.length() != 4 || !this.bankAccount.Bank__c.startsWith('0')) {
            throw new EFTFileException(null, '', 'Invalid Bank Account Bank #. Please update the payment bank account. Bank #\'s must be 4 digits long and start with a 0.');
        }
        String transitNum = '' + this.bankAccount.Transit__c;
        if (transitNum.length() != 5) {
            throw new EFTFileException(null, '', 'Invalid Bank Account Transit #. Please update the payment bank account. Transit #\'s must be 5 digits long.');
        }
        this.eftFileDetail += this.bankAccount.Bank__c + '' + transitNum;
    }
    
    /**
    *    @description : Method to set Account number
    **/
    private void setAccountNumber(){
        this.eftFileDetail += EFTHelper.formatString(String.valueOf(this.bankAccount.Account__c), ' ', 12, 'right');
    }
    
    /**
    *    @description : Method to set Amount
    **/
    private void setAmount(){
        if (amount >= 0) {
            String formattedAmount = String.valueOf(amount).replace('.','');
            this.eftFileDetail += EFTHelper.formatString(formattedAmount, '0', 10, 'left');
        } else {
            throw new EFTFileException('', 'Amount__c', 'Amount must be >= 0');
        }
    }
    
    /**
    *    @description : Method to return the eft file detail as string
    **/
    public String getFileDetailAsString(){
        this.eftFileDetail = 'D';
        this.setPayeeName();
        this.setDueDate();
        this.setOriginatorReferenceNumber();
        this.setTransitNumber();
        this.setAccountNumber();
        this.setAmount();

        if (this.eftFileDetail.length() != 80) {
            throw new EFTFileException(null, '', 'Invalid Detail Generated. Please have a developer look into this: "' + this.eftFileDetail + '"' );
        }
        return this.eftFileDetail;
    }

}