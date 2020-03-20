({
	/**
    * @description Helper method which takes in action and creates promise around it
    * @param      action - action for which callback is set and promise is created around.
    **/
    promiseServerSideCall: function(action) {
        return new Promise(function(resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject(Error(errors[0].message));
                        }
                    } else {
                        reject(Error($A.get("Unknown Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },

    /**
    * @description Helper method to add drawdown to the list
    **/
    add: function(component,event) {
        var drawdownList = component.get("v._drawdownsList");
        drawdownList.push({'sobjectType':'Drawdown__c','Payment_Method__c':'e-Transfer','Reference_Notes__c':'Payment to Client'});
        component.set("v._drawdownsList",drawdownList);
    },

    /**
    * @description Helper method to remove selected drawdown from the list
    **/
    remove: function(component,event) {
       	var drawdownList = component.get("v._drawdownsList");
       	if(drawdownList.length > 1) drawdownList.splice(event.target.id,1);
       	component.set("v._drawdownsList",drawdownList);
    },

    /**
    * @description Helper method to calculate payoutBalance
    **/
    calculatePayoutBalance : function(component,event,helper) {
        var action = component.get("c.calculateLoanInterestAndBalance");
        action.setParams({
            opportunity : event.getParam('fields'),
            drawdownsList : component.get("v._drawdownsList")
        });
        this.promiseServerSideCall(action).then(
                $A.getCallback(function(result){
                    helper.showPayoutBalance(component,event,result);
                    $A.util.toggleClass(component.find("spinner"),"slds-hide"); 
                })
            ).catch(
                $A.getCallback(function(error){
                    if(!$A.util.isEmpty(error)){
                        var errorMessage = $A.get("e.force:showToast");
                        errorMessage.setParams({
                            "type" : "error",
                            "message": error.message
                        });
                        errorMessage.fire();
                        $A.util.toggleClass(component.find("spinner"),"slds-hide"); 
                    }
            })
        );
    },

    /**
    * @description Helper method to remove selected drawdown from the list
    **/
    showPayoutBalance : function(component, event, resultMap) {  
        $A.createComponents([
            ["aura:html",{"tag":"div","body":"Payout Details","HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["c:payoutDetails",
                {   'principal': resultMap && resultMap.hasOwnProperty('principal') ? resultMap['principal'] : 0.00,
                    'interest': resultMap && resultMap.hasOwnProperty('interest') ? resultMap['interest'] : 0.00,
                    'balance': resultMap && resultMap.hasOwnProperty('balance') ? resultMap['balance'] : 0.00
                }
            ]
        ],
        function(components, status, errorMessage){
            if (status === "SUCCESS") {
                component.find("overlayLib").showCustomModal({
                   header: components[0],
                   body: components[1],
                   cssClass : "slds-modal_medium",
                   showCloseButton: true,
                   closeCallback: function() {}
               }).then(function(overlay){
                    // we need to set the modal instance in an attribute to call its methods
                    component.set("v.overlayPanel",[overlay]);
               });
            }else{
                console.error(errorMessage);
            }
        });
    },

    /**
    * @description Helper method to remove selected drawdown from the list
    **/
    createPayoutStatement : function(component, event, resultMap) {  
        var action = component.get("c.calculateLoanInterestAndBalance");
        action.setParams({
            opportunity : event.getParam('fields'),
            drawdownsList : component.get("v._drawdownsList")
        });
        this.promiseServerSideCall(action).then(
                $A.getCallback(function(result){
                    $A.get("e.force:navigateToURL").setParams({ 
                        "url": "/apex/PayoutStatement?contact="+JSON.stringify(component.get("v._contact"))+'&lawFirm='+component.get("v._lawFirm")+'&lawyer='+component.get("v._lawyer")+
                                    '&opportunity='+JSON.stringify(event.getParam('fields'))+'&drawdowns='+JSON.stringify(result['drawdowns'])+'&principal='+JSON.stringify(result['principal'])+
                                    '&interest='+JSON.stringify(result['interest'])+'&balance='+JSON.stringify(result['balance'])+'&businessunit='+component.get("v._selectedBusinessUnit")
                    }).fire();
                    $A.util.toggleClass(component.find("spinner"),"slds-hide"); 
                })
            ).catch(
                $A.getCallback(function(error){
                    if(!$A.util.isEmpty(error)){
                        var errorMessage = $A.get("e.force:showToast");
                        errorMessage.setParams({
                            "type" : "error",
                            "message": error.message
                        });
                        errorMessage.fire();
                        $A.util.toggleClass(component.find("spinner"),"slds-hide"); 
                    }
            })
        );
    },

    /**
    * @description Helper method to do the validations
    **/
    validate : function(component, event) {  
        var errorsList = [];
        var counter = 1;
        // validate amount 

        // validate payout date 
        if(!event.getParam('fields')['Payout_Date__c']){
            errorsList.push(counter+'. '+$A.get("$Label.c.Payout_Date_is_Blank"));
            counter++;
        }

        // validate interest
        if(!event.getParam('fields')['Interest_Rate__c']){
            errorsList.push(counter+'. '+$A.get("$Label.c.Interest_Rate_is_Blank"));
            counter++;
        }

        // validate interest compound period
        if(!event.getParam('fields')['Interest_Compounding_Period__c']){
            errorsList.push(counter+'. '+$A.get("$Label.c.Interest_Compounding_Period_is_Blank"));
            counter++;
        }

        // validate interest compound frequency
        if(!event.getParam('fields')['Compounding_Interest__c'] && event.getParam('fields')['Interest_Compounding_Period__c'] == 'Compounding Interest'){
            errorsList.push(counter+'. '+$A.get("$Label.c.Interest_Compounding_Frequency_is_Blank"));
            counter++;
        }

        // validate minimum interest period
        if(!event.getParam('fields')['Minimum_Interest_Period__c'] && event.getParam('fields')['Interest_Compounding_Period__c'] == 'Compounding Interest'){
            errorsList.push(counter+'. '+$A.get("$Label.c.Minimum_Interest_Period_is_Blank"));
            counter++;
        }

        // validate interest defferal period
        if(!event.getParam('fields')['Interest_Deferral_Period__c'] && event.getParam('fields')['Interest_Compounding_Period__c'] == 'Compounding Interest'){
            errorsList.push(counter+'. '+$A.get("$Label.c.Interest_Defferal_Period_is_Blank"));
            counter++;
        }

        // validate drawdowns
        var drawdownsList = component.get("v._drawdownsList");
        if(drawdownsList){
            for(var i=0;i<drawdownsList.length;i++){
                if(!drawdownsList[0].Date__c || !drawdownsList[0].Amount__c){
                    errorsList.push(counter+'. '+$A.get("$Label.c.Invalid_Drawdowns"));
                }
            }
        }

        // check drawdowns
        component.set("v._errorsList",errorsList);
    },

})