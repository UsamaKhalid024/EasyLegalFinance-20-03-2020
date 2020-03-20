({
    doInit: function(component, event, helper){
        helper.convertOptionsToLightning(component);
    },
	inlineEditName : function(cmp, event, helper) {
		cmp.set("v.editMode", true);
	},
    onGroup: function(cmp, evt) {
        var selected = evt.getSource().get("v.class");
        cmp.set("v.selectedOption", selected);

        var isInline = cmp.get("v.inline");
        if(isInline)
        {
            cmp.set("v.editMode", false);
            
            var enableSave = cmp.get('v.enableSaveAction');
            if(enableSave)	$A.enqueueAction(enableSave);
        }
    },
    updateLightningOpts: function(component, event, helper){
        helper.convertOptionsToLightning(component);
    },
    onclickLightningRadio: function(component, event, helper){
        setTimeout(function(){
            var isInline = component.get("v.inline");
            if(isInline)
            {
                component.set("v.editMode", false);
                
                var enableSave = component.get('v.enableSaveAction');
                if(enableSave)	$A.enqueueAction(enableSave);
            }
        },200);
        
    }
})