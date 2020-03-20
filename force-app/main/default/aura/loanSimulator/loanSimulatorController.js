({
	/**
    * @description Method to add drawdown to the list 
    */
    addDrawdown : function(component,event,helper){
    	helper.add(component,event);
    },
    /**
    * @description Method to remove the selected drawdown
    */
    removeDrawdown : function(component,event,helper){
    	helper.remove(component,event);
    },
    /**
    * @description Method to remove the selected drawdown
    */
    setButtonName : function(component,event,helper){
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
    	component.set("v._selectedButton",event.getSource().get("v.name"));
    },
    /**
    * @description Method to get the opportunity info
    */
    handleOnSubmit : function(component,event,helper){
        helper.validate(component,event);
        if($A.util.isEmpty(component.get("v._errorsList"))){
        	if(component.get("v._selectedButton") == 'payoutBalance'){
                event.preventDefault();
        		helper.calculatePayoutBalance(component,event,helper);
        	}else if(component.get("v._selectedButton") == 'payoutStatement'){
                event.preventDefault();
                helper.createPayoutStatement(component,event,helper);
            }
        }else{
            var errorMessage = '';
            for(var i=0;i<component.get("v._errorsList").length;i++){
                errorMessage += (errorMessage != '' ? ' \n ' : '')+component.get("v._errorsList")[i];
            }
            $A.get("e.force:showToast").setParams({"type":"error","message":errorMessage}).fire();
            $A.util.toggleClass(component.find("spinner"),"slds-hide"); 
        }
    },
})