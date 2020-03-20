({
    doInit : function(component, event, helper) {
        /*
        component.set("v.spinner", true);
        
        component.set("v.spinner", false);  
        */
        // first box
        helper.getFirstBox(component).then($A.getCallback(
            function(result){
                
                var results = JSON.parse(result);

                component.set('v.firstBox', results[0].value);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
         // second box
        helper.getSecondBox(component).then($A.getCallback(
            function(result){
                
                var results = JSON.parse(result);

                component.set('v.secondBoxAmount', results[0].value);
                component.set('v.secondBoxOpportunities', results[1].value);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        // fourth box
        // paid off
        helper.getFourthBoxPaidOff(component).then($A.getCallback(
            function(result){
                
                var results = JSON.parse(result);

                component.set('v.FourthBoxPaidOff', results[0].value);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        // fourth box
        // Closed with loan
        helper.getFourthBoxClosedWithLoan(component).then($A.getCallback(
            function(result){
                
                var results = JSON.parse(result);

                component.set('v.FourthBoxClosedWithLoan', results[0].value);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
    },
    
    filterButton : function(component, event, helper){
        /*
        component.set("v.spinner", true);
        
        
        
        helper.getAmountGroupByLawyer(component).then($A.getCallback(
            function(result){
                helper.setDateCustomSettings(component);
                component.set('v.AmountByLawyer', result);
                helper.GetFileTotalAndAmountTotalForLawyer(component);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
        */
    },
    getFirstBox : function(component, event, helper){
        component.set("v.spinner", true);
        
        helper.getFirstBox(component).then($A.getCallback(
            function(result){
                component.set('v.firstBox', result);
                component.set("v.spinner", false);
            }
        )).catch(
            function(errors){
                component.set("v.spinner", false);
                helper.errorsHandler(errors);
            }
        );
        
    }
})