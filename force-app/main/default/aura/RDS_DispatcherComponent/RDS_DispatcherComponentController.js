({
	doInit : function(component, event, helper) {
        var recId = component.get('v.recordId');
        var getAccountAction = component.get('c.getAccount');
        getAccountAction.setParams({
            recordId: recId
        });
        getAccountAction.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                var accountRec = response.getReturnValue();
                console.log('-----> ' + accountRec);
                if(accountRec)
                {
                    if(accountRec.RecordType.Name == 'Client')
                    {
                        /*
                        var evt = $A.get("e.force:navigateToComponent");
                        evt.setParams({
                            componentDef : "c:CustomerViewComponent",
                            componentAttributes: {
                                recordId : accountRec.Id
                            }
                        });
                        evt.fire();
                        */
                        
                        var eUrl= $A.get("e.force:navigateToURL");
                        var url = '/lightning/r/Account/'+accountRec.Id+'/view';
                        if (recId.startsWith('006')) {
                            // Opportunity
                            url += `#/OPPORTUNITY/${recId}`;
                        }
                        eUrl.setParams({
                            "url": url
                        });
                        eUrl.fire();                       
                    }
                    else
                    {
                        var eUrl= $A.get("e.force:navigateToURL");
                        eUrl.setParams({
                            "url": '/'+recId+'?nooverride=1' 
                        });
                        eUrl.fire();
                    }
                }
                else
                {
                    alert('Record not found!');
                }
            }
            else
            {
                alert(response.getErrors()[0].message);
            }
        });
        $A.enqueueAction(getAccountAction);
		
	}
})