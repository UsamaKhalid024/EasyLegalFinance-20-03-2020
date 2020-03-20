/**
 * @File Name          : EFTFile.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/11/2019, 11:03:01 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/22/2019, 1:08:28 PM   Seth Boyd     Initial Version
**/
public with sharing class EFTFile {
    private Id[] spIds;
    private Scheduled_Payment__c[] spList;
    private Map<Id, Bank_Account__c> bankAccountList;
    private Decimal amountTotal = 0;
    private Integer transactionCount = 0;
    private Date dueDate;

    public EFTFile(Id[] spIds) {
        this.dueDate = DateUtil.today();
        this.spIds = spIds;
    }

    public EFTFile(Id[] spIds, Date dueDate) {
        this.dueDate = dueDate;
        this.spIds = spIds;
    }

    private void fetchData() {
        // First grab Scheduled Payments with Bank Account Info
        this.spList = [
            Select
                Id, Name, Amount__c, Status__c, Current_Bank_Account_Id__c, Can_Send_to_Bank__c, // Scheduled Payment Fields
                Opportunity__r.AccountId // Opportunity Fields
            FROM Scheduled_Payment__c
            WHERE Id in :this.spIds
            ORDER BY Current_Bank_Account_Id__c
        ];

        // Collect Account Ids
        Set<Id> bankAccountIds = new Set<id>();
        for (Scheduled_Payment__c sp : this.spList) {
            bankAccountIds.add(sp.Current_Bank_Account_Id__c);
        }

        // Fetch Accounts with Bank Account and Contact information mapped by Id for ease of use
        this.bankAccountList = new Map<Id, Bank_Account__c>([
            SELECT Id, Name, Bank__c, Transit__c, Account__c, Client__r.Name
            FROM Bank_Account__c
            WHERE Id in :bankAccountIds
            ORDER BY Id
        ]);
    }

    public class GroupedPayments {
        public Decimal total {public get; private set;}
        public Scheduled_Payment__c[] spList;
        public String referenceNumber;
        public Bank_Account__c bankAccount;

        public GroupedPayments(Bank_Account__c bankAccount) {
            this.total = 0;
            this.spList = new Scheduled_Payment__c[]{};
            this.bankAccount = bankAccount;
            Blob blobKey = crypto.generateAesKey(128);
            String key = EncodingUtil.base64encode(blobKey).remove('/');
            //String key = crypto.generateDigest('MD5', Blob.valueOf(bankAccount.Id)).toString();
            this.referenceNumber = DateUtil.now().format('ddMMyy') + '-' + key.substring(0, 11);
        }

        public void addPayment(Scheduled_Payment__c sp) {
            spList.add(sp);
            total += sp.Amount__c;
            sp.Transaction_Reference_Number__c = referenceNumber;
        }
    }

    public String generateFileText() {

        this.fetchData();

        // initilize Exception Collection
        EFTFileException[] errorList = new EFTFileException[]{};

        String eftFileData = '';
        Map<Id, GroupedPayments> groupedPayments = new Map<Id, GroupedPayments>();

        // Loop over Scheduled Payments and create detail lines
        EFTFileDetail eftFileDetail;
        Datetime now = DateUtil.now();
        for (Scheduled_Payment__c sp : this.spList) {
            // Validate User is able to send current payment (has EFT_Permission or was not the validator)
            if (!sp.Can_Send_to_Bank__c) {
                errorList.add(new EFTFileException(sp.Id, 'Can_Send_to_Bank__c', 'You are not able to send payments that you verified.'));
            }


            // Validate that Status is correctly set
            /*
            if (sp.Status__c != 'Scheduled') {
                errorList.add(new EFTFileException(sp.Id, 'Status__c', 'Scheduled Payment Status must by \'Scheduled\''));
            }
            */


            // Generate line text
            try {
                if (String.isBlank(sp.Current_Bank_Account_Id__c)) {
                    system.debug(sp.Current_Bank_Account_Id__c);
                    throw new EFTFileException(sp.Id, 'Current_Bank_Account_URL__c', 'Scheduled Payment does not have a Bank Account set');
                }
                if (sp.Amount__c <= 0) {
                    throw new EFTFileException(sp.Id, 'Amount__c', 'Scheduled Payment amount must be greater than $0');
                }
                GroupedPayments gp;
                if (groupedPayments.containsKey(sp.Current_Bank_Account_Id__c)) {
                    gp = groupedPayments.get(sp.Current_Bank_Account_Id__c);
                } else {
                    Id baId = sp.Current_Bank_Account_Id__c;
                    Bank_Account__c ba = this.bankAccountList.get(baId);
                    gp = new GroupedPayments(ba);
                    groupedPayments.put(sp.Current_Bank_Account_Id__c, gp);
                }
                sp.Bank_Account__c = sp.Current_Bank_Account_Id__c;
                gp.addPayment(sp);
                //eftFileDetail = new eftFileDetail(this.bankAccountList.get(sp.Current_Bank_Account_Id__c), this.dueDate, sp);
                //eftFileData += eftFileDetail.getFileDetailAsString() + '\r\n';
            } catch (EFTFileException e) {
                // Catch exception and set Scheduled Payment Id
                e.id = sp.Id;
                errorList.add(e);
                //throw e;
            }

            // Update status and trackers
            //this.amountTotal += sp.Amount__c;
            //this.transactionCount += 1;
            sp.Status__c = 'Sent to Bank';
            sp.Sent_to_Bank_Account__c = sp.Current_Bank_Account_Id__c;
            sp.Sent_to_Bank_Date__c = now;
            sp.Sent_to_Bank_By__c = UserInfo.getUserId();
        }

        // Generate Transaction Lines from Grouped Payments
        for (GroupedPayments gp : groupedPayments.values()) {

            try {
                eftFileDetail = new eftFileDetail(gp.bankAccount, this.dueDate, gp.total, gp.referenceNumber);
                eftFileData += eftFileDetail.getFileDetailAsString() + '\r\n';
            } catch (EFTFileException e) {
                errorList.add(e);
                //throw e;
            }
            this.amountTotal += gp.total;
            this.transactionCount += 1;
        }

        // Generate file footer
        EFTFileTrailer eftFileTrailer = new EFTFileTrailer(this.transactionCount, this.amountTotal);
        try {
            eftFileData += eftFileTrailer.getFileTrailerAsString() + '\r\n';
        } catch (EFTFileException e) {
            errorList.add(e);
        }

        if (errorList.isEmpty() == false) {
            System.debug(errorList);
            throw new EFTFileErrorListException(errorList);
        } else {
            // Generate file header
            // Do this last so any exceptions can show up before we create an EFT_File__c object
            EFT_File__c eftFileObj = getEFTFileObj(this.amountTotal, this.transactionCount);
            EFTFileHeader eftFileHeader = new EFTFileHeader(this.dueDate, eftFileObj.File_Number__c);
            try {
                eftFileData = eftFileHeader.getFileHeaderAsString() + '\r\n' + eftFileData; // Prepend header 
                for (Scheduled_Payment__c sp : spList) {
                    sp.EFT_File__c = eftFileObj.Id;
                }
            } catch (EFTFileException e) {
                errorList.add(e);
                throw new EFTFileErrorListException(errorList);
            }
        }

        // update Scheduled Payments' status
        update spList;

        // Need to rework this to utilize the EFT_File__c object now...
        return eftFileData;
    }

    private EFT_File__c getEFTFileObj(Decimal amount, Integer count) {
        EFT_File__c eftFileObj = new EFT_File__c(Total_Amount__c=this.amountTotal, Transaction_Count__c=this.transactionCount);
        insert eftFileObj;
        eftFileObj = [Select Id, Name, File_Number__c From EFT_File__c Where Id = :eftFileObj.Id];
        if (eftFileObj.File_Number__c == '0000') {
            // If File Number is 0000 it is invalid, so we must delete that object and create another so the Auto-number increments
            delete eftFileObj;
            return getEFTFileObj(amount, count);
        }
        return eftFileObj;
    }

    private void attachFile(String fileText, EFT_File__c eftFileObj) {
        Attachment att = new Attachment();
        att.Body = Blob.valueOf(fileText);
        att.Name = 'Banking_Sheet_' + eftFileObj.File_Number__c + '_' + DateUtil.now().format('yyyy_MM_dd_hh_mm_ss') + '.txt';
        att.parentId = eftFileObj.Id;
        insert att;
        String fileURL = URL.getFileFieldURL(att.Id, 'Attachment');
    }
}