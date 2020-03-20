/**
* @description Class used to fetch the lawyer details
**/
public with sharing class LawSocietyReviewController {
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String businessUnit{get;set;}
    public String searchByName{get;set;}
    public String upcomingHearings{get;set;}
    public String currentProceedings{get;set;}
    public String orders{get;set;}
    public String dateReviewed{get;set;}
    public String nextReviewDate{get;set;}
    public String reviewedStatus{get;set;}
    
    public LawSocietyReviewController(){
        Date dt = Date.today();
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('businessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('startDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('endDate');
        String paramSearchByName = ApexPages.currentPage().getParameters().get('searchByName');
        String paramUpcomingHearings = ApexPages.currentPage().getParameters().get('upcomingHearings');
        String paramCurrentProceedings = ApexPages.currentPage().getParameters().get('currentProceedings');
        String paramOrders= ApexPages.currentPage().getParameters().get('orders');
        String paramDateReviewed= ApexPages.currentPage().getParameters().get('dateReviewed');
        String paramNextReviewDate= ApexPages.currentPage().getParameters().get('nextReviewDate');
        String paramReviewedStatus= ApexPages.currentPage().getParameters().get('reviewedStatus');
        
        
        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? Date.valueOf(paramStartDate) : dt.addDays(-30);
        this.endDate = !String.isEmpty(paramEndDate)? Date.valueOf(paramEndDate) : dt;
        this.searchByName = !String.isEmpty(paramSearchByName) && paramSearchByName != null? paramSearchByName : '';
        this.upcomingHearings = !String.isEmpty(paramUpcomingHearings) && paramUpcomingHearings != null? paramUpcomingHearings : '';
        this.currentProceedings = !String.isEmpty(paramCurrentProceedings) && paramCurrentProceedings != null? paramCurrentProceedings : '';
        this.orders = !String.isEmpty(paramOrders) && paramOrders != null? paramOrders : '';
        this.dateReviewed = !String.isEmpty(paramDateReviewed) && paramDateReviewed != null? paramDateReviewed : '';
        this.nextReviewDate = !String.isEmpty(paramNextReviewDate) && paramNextReviewDate != null? paramNextReviewDate : '';
        this.reviewedStatus = !String.isEmpty(paramReviewedStatus) && paramReviewedStatus != null? paramReviewedStatus : 'All';
    }
    public List<Lawyer> getLawyers(){        
        Map<String,Object> result = getLawyersList(this.startDate + '', this.endDate + '', this.businessUnit, this.searchByName, 'SUM(Amount__c)', 'ASC', this.upcomingHearings, this.currentProceedings, this.orders, this.dateReviewed, this.nextReviewDate, this.reviewedStatus);
        return (List<Lawyer>)result.get('lawyers');
    }
    
    /**
    * @description Method to fetch lawyer details
    **/
    @AuraEnabled
    public static Map<String,Object> getLawyersList(String startDate, String endDate, String businessUnit, String searchByName, String field, String direction, String upcomingHearings, String currentProceedings, String orders, String dateReviewed, String nextReviewDate, String reviewedStatus){
       
        Map<String, Object> objectsMap = new Map<String, Object>();
        Set<Id> lawyerIds = new Set<Id>();
        Map<Id, Contact> contactsMap = new Map<Id, Contact>();
        List<Lawyer> lawyersList = new List<Lawyer>();
        
        Date sDate = Date.valueOf(startDate);
        Date eDate = Date.valueOf(endDate);
        String soqlQuery = 'SELECT Opportunity__r.Lawyer__c lawyerId, COUNT_DISTINCT(Opportunity__r.AccountId) file, SUM(Amount__c) amount FROM Drawdown__c WHERE Date__c >= :sDate AND Date__c <= :eDate';
       	soqlQuery += !String.isEmpty(searchByName) && searchByName != null? ' AND (Opportunity__r.Lawyer__r.Name LIKE \'%' + String.escapeSingleQuotes(searchByName) + '%\' OR Opportunity__r.Lawyer__r.Account.Name LIKE \'%' + String.escapeSingleQuotes(searchByName) + '%\')' : '';
        soqlQuery += businessUnit == 'Consolidated' ? ' AND (Opportunity__r.Account.Business_Unit__c = \'ELFI\' OR Opportunity__r.Account.Business_Unit__c = \'Rhino\')' : ' AND Opportunity__r.Account.Business_Unit__c = \''+businessUnit+'\'';
        soqlQuery += ' AND Opportunity__r.StageName = \'Closed With Loan\' AND (Payment_Method__c = \'e-Transfer\' OR Payment_Method__c = \'Cheque\' OR Payment_Method__c = \'Admin Fee\') GROUP BY Opportunity__r.Lawyer__c';
        soqlQuery += ' ORDER BY ' + field + ' ' + direction + ' NULLS LAST';
        
        List<AggregateResult> aggrQueryResult = Database.query(soqlQuery);
        for(AggregateResult aggregateResult : aggrQueryResult){
            if(aggregateResult.get('lawyerId') != null){
                lawyerIds.add((Id)aggregateResult.get('lawyerId'));
            }
        }
        Date dtReviewed = !String.isEmpty(dateReviewed) && dateReviewed != null? Date.valueOf(dateReviewed) : null;
        Date nxtReviewDate = !String.isEmpty(nextReviewDate) && nextReviewDate != null? Date.valueOf(nextReviewDate) : null;
        
                
        If(!lawyerIds.isEmpty()){
            Date dt = Date.today();
            
            String soqlContact = 'SELECT Id, Name, AccountId, Account.Name, Upcoming_Hearings__c, Current_Proceedings__c,';
            soqlContact += 'Orders__c, Date_Reviewed__c, Next_Review_Date__c';
            soqlContact += ' FROM Contact';
            soqlContact += ' WHERE RecordType.DeveloperName = \'Lawyers\'';
            soqlContact += !String.isEmpty(reviewedStatus) && reviewedStatus == 'Reviewed'? ' AND Date_Reviewed__c <= :dt AND (Next_Review_Date__c = null OR Next_Review_Date__c >= :dt)'  : '';
            soqlContact += !String.isEmpty(reviewedStatus) && reviewedStatus == 'Not Reviewed'? ' AND Date_Reviewed__c = null' : '';
            soqlContact += !String.isEmpty(reviewedStatus) && reviewedStatus == 'Over due'? ' AND Next_Review_Date__c < :dt' : '';
            soqlContact += !String.isEmpty(upcomingHearings)? ' AND Upcoming_Hearings__c =:upcomingHearings' : '';
            soqlContact += !String.isEmpty(currentProceedings)? ' AND Current_Proceedings__c =:currentProceedings' : '';
            soqlContact += !String.isEmpty(orders)? ' AND Orders__c =:orders' : '';
            soqlContact += dtReviewed != null? ' AND Date_Reviewed__c =:dtReviewed' : '';
            soqlContact += nxtReviewDate != null? ' AND Next_Review_Date__c =:nxtReviewDate' : '';
            soqlContact += ' AND Id in:lawyerIds';
            
            contactsMap = new Map<Id, Contact>(
                (List<Contact>)Database.query(soqlContact)
            );
        }
        
        if(!aggrQueryResult.isEmpty()){
            for(AggregateResult aggregateResult : aggrQueryResult){
                if(aggregateResult.get('lawyerId') != null && contactsMap.containsKey((Id)aggregateResult.get('lawyerId'))){
                    lawyersList.add(
                        new Lawyer(
                            contactsMap.get((Id)aggregateResult.get('lawyerId')),
                            Integer.valueof(aggregateResult.get('file')), 
                            Double.valueof(aggregateResult.get('amount'))                            
                        )
                    );
                }
            }
        }
        
        objectsMap.put('lawyers',lawyersList);
        objectsMap.put('isCurrentUserSeeLawSocietyReviewReport',[SELECT Id, Law_Society_Review__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].Law_Society_Review__c);
        return objectsMap;
    }
    
    /**
    * @description Method to fetch lawyer details
    **/
    @AuraEnabled
    public static void saveContacts(String contactsListJSON){
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Lawyer> lawyersList = (List<Lawyer>)JSON.deserialize(contactsListJSON,List<Lawyer>.class);
        for(Lawyer lawyer : lawyersList){
            contactsToUpdate.add(lawyer.contact);
        }
        
        update contactsToUpdate;
    }
    
    /**
    * @description Method to save new note
    **/
    @AuraEnabled
    public static void saveNewNote(String contentNote, String contactId){
        contentNote = contentNote.escapeJava().escapeHtml3().escapeHtml4();
        try{
            if(!String.isBlank(contentNote)){
                ContentNote contentNoteRecord = new ContentNote(Title='N/A',Content=Blob.valueOf(contentNote)); 
                insert contentNoteRecord;
                ContentDocument contentDocument = [SELECT Id from ContentDocument where Id =: contentNoteRecord.Id];
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink(ContentDocumentId=contentDocument.Id,LinkedEntityId=contactId,ShareType='V',Visibility='AllUsers');
                insert contentDocumentLink;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Method to fetch saved notes
    **/
    @AuraEnabled
    public static List<Map<String,Object>> getContentNotes(Id contactId){
        List<Map<String,Object>> recordsList = new List<Map<String,Object>>();
        Set<Id> noteIds = new Set<Id>();
        List<Contact> contactList = [SELECT Id,(SELECT Id from AttachedContentNotes) FROM Contact WHERE Id = :contactId];
        for(AttachedContentNote attachedContentNote : contactList[0].AttachedContentNotes){
            noteIds.add(attachedContentNote.Id);
        }
        for(ContentNote contentNote : [SELECT Id, Title, Content, CreatedDate, CreatedBy.Name,TextPreview FROM ContentNote WHERE Id IN: noteIds ORDER BY CreatedDate DESC]){
            recordsList.add(new Map<String,Object>{'CreatedDate' => contentNote.CreatedDate, 'CreatedBy' => contentNote.CreatedBy.Name, 'Content' => contentNote.Content.toString().unescapeHtml4().unescapeHtml3().unescapeJava()});
        }
        return recordsList;
    }    
    /**
    * @description Lawyer Wrapper
    **/
    public class Lawyer {
        @AuraEnabled
        public Contact contact{get;set;}
        @AuraEnabled
        public Decimal outstandingBalance{get;set;}
        @AuraEnabled
        public Integer noOfAccountFiles{get;set;}

        /**
        * @description Constructor
        **/
        public Lawyer(Contact contact, Integer noOfAccountFiles, Decimal outstandingBalance){
            this.contact = contact;
            this.outstandingBalance = outstandingBalance;
            this.noOfAccountFiles = noOfAccountFiles;
        }
    }
}