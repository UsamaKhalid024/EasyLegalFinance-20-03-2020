({
   selectRecord : function(component, event, helper){      
    // get the selected record from list  
      var getSelectRecord = component.get("v.oRecord");
    // call the event   
      var compEvent = component.getEvent("oSelectedRecordEvent");
    // set the Selected sObject Record to the event attribute.  
         compEvent.setParams({"recordByEvent" : getSelectRecord });  
    // fire the event  
         compEvent.fire();
    },
    doinit: function(component, event, helper){
        var fieldsList = component.get('v.additionalDisplayFields');
        var metaVal = "";
        fieldsList.split(',').forEach(function(ele){
            if(ele)
            {
                var thisVal = component.get("v.oRecord."+ele);
                if(thisVal){
                    metaVal = metaVal + " • " + component.get("v.oRecord."+ele);
                }                
            }
        });
        component.set('v.metaValue', metaVal);
    }
})