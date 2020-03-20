({
    convertOptionsToLightning : function(component) {
        var options = component.get('v.options');
        if(options){
            var lOpts = [];
            options.forEach(function(ele){
                var lop = {label: ele, value: ele};
                lOpts.push(lop);
            });
            component.set('v.lightningoptions',lOpts);
        }
	}
})