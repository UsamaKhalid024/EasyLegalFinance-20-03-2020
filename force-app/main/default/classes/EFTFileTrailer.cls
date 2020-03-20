/**
*    @description : EFT File Trailer
**/
public with sharing class EFTFileTrailer {
    private Decimal amountTotal;
    private Integer transactionCount;
    
    private String eftFileTrailer;
    
    /**
    *    @description : Constructor
    **/
    public EFTFileTrailer(Integer transactionCount, Decimal amountTotal) {
        this.transactionCount = transactionCount;
        this.amountTotal = amountTotal;
    }
    
    /**
    *    @description : Method to set total number of transactions
    **/
    private void setTotalNumberOfTransactions(){
        this.eftFileTrailer += EFTHelper.formatString(String.valueOf(this.transactionCount), '0', 8, 'left');
    }
    
    /**
    *    @description : Method to set total value of transactions
    **/
    private void setTotalValue(){
        String formattedTotalValue = String.valueOf(this.amountTotal).replace('.','');
        this.eftFileTrailer += EFTHelper.formatString(formattedTotalValue, '0', 14, 'left');
    }
    
    /**
    *    @description : Method to set total value of transactions
    **/
    private void setFiller(){
        this.eftFileTrailer += EFTHelper.formatString('' ,'' , 57, 'left');
    }
    
     /**
    *    @description : Method to return the eft file trailer as string
    **/
    public String getFileTrailerAsString(){
        this.eftFileTrailer = 'T';
        this.setTotalNumberOfTransactions();
        this.setTotalValue();
        this.setFiller();

        if (this.eftFileTrailer.length() != 80) {
            throw new EFTFileException(null, '', 'Invalid Trailer Generated. Please have a developer look into this: "' + this.eftFileTrailer + '"' );
        }
        return this.eftFileTrailer;
    }
}