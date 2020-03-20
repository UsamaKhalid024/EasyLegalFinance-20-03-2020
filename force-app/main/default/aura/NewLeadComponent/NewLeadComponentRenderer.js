({
    afterRender : function( component, helper ) {

        this.superAfterRender();
        var didScroll = false;
        window.onscroll = function() {
            didScroll = true;
        };

        // periodically attach the scroll event listener
        // so that we aren't taking action for all events
        var scrollCheckIntervalId = setInterval( $A.getCallback( function() {

            // since this function is called asynchronously outside the component's lifecycle
            // we need to check if the component still exists before trying to do anything else
            if ( didScroll && component.isValid() ) {

                didScroll = false;
                var cmpTarget = component.find('headerDiv');
                if(window['scrollY'] <= 5){
                    
                    $A.util.removeClass(cmpTarget, 'banner-style-fixed');
        			$A.util.addClass(cmpTarget, 'banner-style');
                    
                }else if(window['scrollY'] > 5){                    
                    
                    $A.util.removeClass(cmpTarget, 'banner-style');
        			$A.util.addClass(cmpTarget, 'banner-style-fixed');
                }
            }

        }), 100 );

        component.set( 'v.scrollCheckIntervalId', scrollCheckIntervalId );

    },

    unrender : function( component, helper ) {

        this.superUnrender();

        var scrollCheckIntervalId = component.get( 'v.scrollCheckIntervalId' );

        if ( !$A.util.isUndefinedOrNull( scrollCheckIntervalId ) ) {
            window.clearInterval( scrollCheckIntervalId );
        }

    }
})