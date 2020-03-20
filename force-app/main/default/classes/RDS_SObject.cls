public with sharing virtual class RDS_SObject {
    
    public SObject sObj;

    // default constructor
    public RDS_SObject() {

    }

    public RDS_SObject(SObject sObj) {
        this.sObj = sObj;
    }


    /**
     * the function queries the object based on id from database
     * makes sure no field is missed to avoid "field referred without query exception"
     */
    public void initFromDb(String fldList) {
        if(this.sObj != null && this.sObj.Id != null) {
            String objType = this.SObj.Id.getSObjectType()+'';

            String fieldlist = RDS_Util.getQueryStringForSObject(objType);
            
            if(fldList != null && fldList != '') {
                fieldlist = fieldlist + ',' + fldList;
            }
            /**
             * query from db and reinitialize the sObject
             */
            String query = 'SELECT ' + fieldlist + ' FROM ' + objType + ' WHERE id=\'' + this.sObj.Id + '\'';
            System.debug('Query: ' + query);
            List<SObject> lstSObj = Database.query(query);
            if(lstSObj.size() > 0) {
                sObj = lstSObj[0];
            }
        }
    }
}