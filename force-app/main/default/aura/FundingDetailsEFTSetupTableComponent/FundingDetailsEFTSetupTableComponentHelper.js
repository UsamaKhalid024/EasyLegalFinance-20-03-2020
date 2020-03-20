({
    setScheduledPaymentSelectionStatus : function(selected, spList) {
        for (var i = 0; i < spList.length; i++) {
            spList[i]._selected = selected;
        }
        return spList;
    },

    allScheduledPaymentsSelected : function(spList) {
        var foundUnselected = false;
        for (var i = 0; i < spList.length; i++) {
            foundUnselected = foundUnselected || !spList[i]._selected;
        }
        return !foundUnselected;
    },

    setSelectedScheduledPaymentsEFTNumbers : function(spList, eftNum) {
        for (var i = 0; i < spList.length; i++) {
            if (spList[i]._selected) {
                spList[i]._eftNumber = eftNum;
            }
        }
        return spList;
    },

    downloadBankingSheet : function(spList) {
        this.showToast("Not yet implemented", "This will trigger a download of a newly generated banking sheet. Should this also save beforehand?", "warning", "sticky");
    },

    savePaymentInformation: function(spList) {
        this.showToast("Not yet implemented", "This will save the payment information and generate Drawdown records. Should this only the selected records or all of them?", "warning", "sticky");
    },

    showToast : function(title, message, type, mode) {
        mode = mode || 'dismissible';
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        toastEvent.fire();
    }    
})